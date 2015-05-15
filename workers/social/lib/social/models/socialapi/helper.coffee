Bongo          = require "bongo"
{secure, daisy, dash, signature, Base} = Bongo
Validators = require '../group/validators'
{permit}   = require '../group/permissionset'

fetchGroup = (client, callback)->
  groupName = client.context.group or "koding"
  JGroup = require '../group'
  JGroup.one slug : groupName, (err, group)=>
    return callback err  if err
    return callback {error: "Group \"#{groupName}\" not found"}  unless group

    {delegate} = client.connection
    return callback {error: "Request not valid"} unless delegate
    group.canReadGroupActivity client, (err, res)->
      if err then return callback {error: "Not allowed to open this group"}
      else callback null, group

secureRequest = (rest...)->
  return secure requester rest...

permittedRequest = (opts)->
  {permissionName} = opts
  return permit permissionName,
    success: requester opts

requester = ({fnName, validate})->
  return (client, options = {}, callback)->
    if validate?.length > 0
      errs = []
      for property in validate
        errs.push property unless options[property]
      if errs.length > 0
        msg = "#{errs.join(', ')} fields are required for #{fnName}"
        return callback { message: msg }

    doRequest fnName, client, options, callback

ensureGroupChannel = (client, callback)->
  fetchGroup client, (err, group)->
    return callback err  if err
    return callback { message: "Group not found" } unless group
    group.createSocialApiChannels client, (err, result)->
      return callback err  if err
      callback null, result.socialApiChannelId

doRequest = (funcName, client, options, callback)->
  fetchGroup client, (err, group)->
    return callback err if err

    {connection:{delegate}} = client
    {profile:{nickname}}    = delegate

    delegate.createSocialApiId (err, socialApiId)->
      return callback err if err

      options.groupChannelId  = group.socialApiChannelId
      options.groupName       = group.slug
      options.accountId       = socialApiId
      options.accountNickname = nickname
      options.showExempt    or= delegate.isExempt
      options.sessionToken  or= client.sessionToken
      options.clientIP        = client.clientIP

      bareRequest funcName, options, callback

bareRequest = (funcName, options, callback)->
  requests = require './requests'
  requests[funcName] options, callback

paymentRequest = (funcName, options, callback)->
  requests = require './payment_requests'
  requests[funcName] options, callback

module.exports = {
  ensureGroupChannel
  permittedRequest
  doRequest
  secureRequest
  fetchGroup
  bareRequest
}
