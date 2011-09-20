var mongo = require('mongodb');
var util = require('util');
var helpers = require('./utility');

//console.log(util.inspect(mongo, true, 1));

var host = 'localhost';
var dburl = 'mongodb://noodle:nudelsalat@staff.mongohq.com:10026/noodle'


// readconf and start db
helpers.readRelJson("./lib/config.json",function(err,conf){
    
    if(err) {
        console.log("ERROOROROROROROROR " + err);
        return;
    }

    var Db = mongo.Db;
    var Server = mongo.Server;
    var client = new Db(conf.dbname, new Server(conf.dbserver,conf.dbport, {}))
   
    console.log(conf.dbuser);
    client.open(function(err, p_client) {
        client.authenticate(conf.dbuser,conf.dbpass, function() {
            client.collection('polls',mainloop);
        });
    });
});


var mainloop = function(err,collection) {
    var app = require('express').createServer();
    
    app.get('/poll/:id', function(req, res){
        collection.find({"id":req.params.id},function(err,cursor){
        
            if (err) {
                res.send("error");
                return;
            }

            cursor.each(function(err,item){
                res.send(item);
            });
        });
    });
    
    app.get('/poll/:id/new/:value', function(req, res){
        res.send('New Entry' + req.params.id);
        collection.insert({"id": req.params.id, "value": ["0",req.params.value]},function(err,docs){
            if (err) {
                console.log(err);
            }
        });
    });
    
    app.listen(3000);
};



/**

test = function (err, collection) {
    collection.insert({a:2}, function(err, docs) {
        
        collection.count(function(err, count) {
            if (err) {
                console.log(err);
                return;
            }
            console.log(count);
        });

        // Locate all the entries using find
        collection.find().toArray(function(err, results) {
            if (err) {
                console.log(err);
                return;
            }
            console.log(results.length);          
            client.close();
        });
    });
    });
};


/**


*/
