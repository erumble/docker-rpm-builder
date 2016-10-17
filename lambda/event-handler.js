console.log('Loading function');

const crypto   = require('crypto'),
      bufferEq = require('buffer-equal-constant-time'),
      event    = require('./test_data.json'),
      semver   = require('semver');

var secret = 'ic638bFLYi6bKzbTGpfAo53hxq8B2NXA8l1NxPL6';

function sign_request(key, request) {
  return 'sha1=' + crypto.createHmac('sha1', key).update(request).digest('hex');
};

//exports.handler = function(event, context, callback) {
  console.log('Recieved event:');
//  console.log(JSON.stringify(event, null, ' '));
  
  var calculated_signature = new Buffer(sign_request(secret, JSON.stringify(event.body)));
  console.log('X-GitHub-Signature: %s', event.headers['X-Hub-Signature']);
  console.log('Calculated-Signature: %s', calculated_signature);

  // check failure conditions
  if (!bufferEq(new Buffer(event.headers['X-Hub-Signature']), calculated_signature)) {
    //callback(new Error('X-Hub-Signature does not match request signature'));
    return console.error('X-Hub-Signature does not match request signature');
  } 
  else if (event.headers['X-GitHub-Event'] != 'release' ) {
    //callback(new Error('GitHub event is not a release, aborting...'));
    return console.error('GitHub event is not a release, aborting...');
  } 
  else if (!semver.valid(event.body.release.tag_name)) {
    //callback(new Error('%s is not a valid semver, aborting build...', event.body.release.tag_name));
    return console.error('%s is not a valid semver, aborting build...', event.body.release.tag_name);
  }
  else {
    console.log('Building Release: %s', event.body.release.tag_name);
    // add code to launch ECS container
  }

//};
