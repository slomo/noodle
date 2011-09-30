mongo = require 'mongodb'
util = require 'util'
helpers = require './utility'
express = require 'express'
# cashew = require 'cashew'
log = require('log4js').getLogger()


class Store

    constructor: (conf,cb) ->
        client = new mongo.Db conf.dbname, new mongo.Server(conf.dbserver,conf.dbport,{})
        that = @

        client.open (err, p_client) ->
            client.authenticate conf.dbuser, conf.dbpass, (err, replies) ->
                client.collection 'polls', (err,collection) ->
                    that._polls = collection
                    client.collection 'votes', (err,collection) ->
                        that._votes = collection
                        cb null, that

    getVote: (id,cb) ->
        @get id, @_votes, Vote, cb

    getPoll: (id,cb) ->
        @get id, @_polls, Poll, cb

    getVotesByPoll: (pid, cb) ->
        cursor = @_votes.find {pid: pid}
        cursor.toArray cb

    get: (id,coll,cl,cb) ->
        coll.findOne {id: id}, (err,data) ->
            if err
                cb err, null
            else
                ret =  new cl data if data
                cb null, ret

    put: (data,cb) ->
        target = @_polls if data instanceof Poll
        target = @_votes if data instanceof Vote
        target.update {id: data.id}, data, {safe:true}, cb

class Poll

    constructor : (data) ->
        @id = data.id
        @name = data.name


class Vote
    constructor : (data) ->
        @id = data.id

class NotFound extends Error
    constructor : (msg) ->
        @name = 'NotFound'
        Error.call(@, msg)
        Error.captureStackTrace(@, arguments.callee)



start = (store) ->
    app = express.createServer()
    app.use express.bodyParser()
    app.error (err,req,res,next) ->
        if err instanceof NotFound
            res.writeHead 404
        else
            res.writeHead 500
        res.end()

    app.get '/poll/:id', (req,res,next) ->
        id = parseInt(req.params.id)
        store.getPoll id, (err,poll) ->
            if err or not poll
                next (new NotFound 'Did got that one')
            else
                store.getVotesByPoll id, (err,votes) ->
                    poll.votes = votes
                    res.send(poll)

    app.post '/poll', (req,res,next) ->
        console.log req.body

    app.listen 3000



helpers.readRelJson './etc/config.json', (err,conf) ->
    if err
        log.error "unable to read config" + err
    else
        new Store conf, (err,store) ->
            if err
                console.log err
            else
                start (store)

