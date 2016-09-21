console.log('Loading function');

var event = require('./test_data.json');
var secret = 'ic638bFLYi6bKzbTGpfAo53hxq8B2NXA8l1NxPL6';

const crypto   = require('crypto')
    , bufferEq = require('buffer-equal-constant-time');

function sign_request(key, request) {
  return 'sha1=' + crypto.createHmac('sha1', key).update(request).digest('hex');
};

//exports.handler = function(event, context) {
  console.log('Recieved event:');
//  console.log(JSON.stringify(event, null, ' '));
  
  var calculated_signature = new Buffer(sign_request(secret, JSON.stringify(event.body)));
  console.log('X-GitHub-Signature: %s', event.headers['X-Hub-Signature']);
  console.log('Calculated-Signature: %s', calculated_signature);

  if (bufferEq(new Buffer(event.headers['X-Hub-Signature']), calculated_signature)) {
    return console.error('X-Hub-Signature does not match request signature');
  };

  var semver = require('semver');
  if (event.headers['X-GitHub-Event'] == 'release' ) {
    if (semver.valid(event.body.release.tag_name)) {
      console.log('Building Release: %s', event.body.release.tag_name);
      // add code to launch ECS container
    }
    else {
      console.log('%s is not a valid semver, aborting build...', event.release.tag_name);
    }
  }
  else {
    console.log('GitHub event is not a release, aborting...');
  }

//};
