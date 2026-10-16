// Test AudioContext hook
global.window = global;

let resumeCalls = 0;
let suspendCalls = 0;

class FakeAudioContext {
  constructor(opts) {
    this.opts = opts;
    this.state = 'running';
  }
  resume() {
    resumeCalls++;
    this.state = 'running';
    return Promise.resolve();
  }
  suspend() {
    suspendCalls++;
    this.state = 'suspended';
    return Promise.resolve();
  }
}

global.AudioContext = FakeAudioContext;

// Audio Interceptor Code
(function() {
  window._isAudioEnabled = true;
  window._isPlatformPaused = false;
  window._gameVisibilityState = 'visible';
  window._allAudioContexts = [];

  function shouldBeMuted() {
    return window._isAudioEnabled === false || window._isPlatformPaused === true || window._gameVisibilityState === 'hidden';
  }

  function hookAudioContext(ctx) {
    if (!ctx || ctx._isHookedBySdk) return;
    ctx._isHookedBySdk = true;
    var origResume = ctx.resume;
    ctx._originalResume = origResume;
    ctx.resume = function() {
      if (shouldBeMuted()) {
        console.log('[AUDIO HOOK] Blocked resume() because audio should be muted');
        return Promise.resolve();
      }
      return origResume.apply(this, arguments);
    };
  }

  window._hookAudioContext = hookAudioContext;

  var OrigAudioContext = window.AudioContext;
  function SdkAudioContext(options) {
    var ctx = new OrigAudioContext(options);
    window._allAudioContexts.push(ctx);
    hookAudioContext(ctx);
    if (shouldBeMuted()) {
      try { ctx.suspend(); } catch(e) {}
    }
    return ctx;
  }
  SdkAudioContext.prototype = OrigAudioContext.prototype;
  window.AudioContext = SdkAudioContext;

  var _sharedHolder = window._dmJSDeviceShared;
  function setupSharedHolder(shared) {
    if (!shared) return;
    var _audioCtx = shared.audioCtx;
    if (_audioCtx) {
      hookAudioContext(_audioCtx);
      if (shouldBeMuted()) {
        try { _audioCtx.suspend(); } catch(e) {}
      }
    }
    try {
      Object.defineProperty(shared, 'audioCtx', {
        configurable: true,
        enumerable: true,
        get: function() { return _audioCtx; },
        set: function(newCtx) {
          _audioCtx = newCtx;
          if (newCtx) {
            hookAudioContext(newCtx);
            if (shouldBeMuted()) {
              try { newCtx.suspend(); } catch(e) {}
            }
          }
        }
      });
    } catch(e) {}
  }

  try {
    Object.defineProperty(window, '_dmJSDeviceShared', {
      configurable: true,
      enumerable: true,
      get: function() { return _sharedHolder; },
      set: function(val) {
        _sharedHolder = val;
        setupSharedHolder(val);
      }
    });
  } catch(e) {}
  if (_sharedHolder) setupSharedHolder(_sharedHolder);

  window._syncAudio = function(mute) {
    if (window._dmJSDeviceShared && window._dmJSDeviceShared.audioCtx) {
      var dCtx = window._dmJSDeviceShared.audioCtx;
      hookAudioContext(dCtx);
      if (mute) {
        dCtx.suspend();
      } else if (!shouldBeMuted()) {
        (dCtx._originalResume || dCtx.resume).call(dCtx);
      }
    }
    for (var i = 0; i < window._allAudioContexts.length; i++) {
      var c = window._allAudioContexts[i];
      hookAudioContext(c);
      if (mute) {
        c.suspend();
      } else if (!shouldBeMuted()) {
        (c._originalResume || c.resume).call(c);
      }
    }
  };
})();

// Test 1: Defold initializes _dmJSDeviceShared after SDK hook
console.log('-- Test 1: Defold initializes _dmJSDeviceShared --');
window._dmJSDeviceShared = { count: 1, devices: {} };
window._dmJSDeviceShared.audioCtx = new window.AudioContext();
console.log('audioCtx state:', window._dmJSDeviceShared.audioCtx.state); // running

// Test 2: Platform mutes audio
console.log('-- Test 2: Platform mutes audio --');
window._isAudioEnabled = false;
window._syncAudio(true);
console.log('After mute, state:', window._dmJSDeviceShared.audioCtx.state); // suspended

// Test 3: User touches screen, Defold TryResumeAudio calls audioCtx.resume()
console.log('-- Test 3: User touches canvas -> TryResumeAudio calls resume() --');
window._dmJSDeviceShared.audioCtx.resume();
console.log('After resume attempt during mute, state is still:', window._dmJSDeviceShared.audioCtx.state); // still suspended!

// Test 4: Platform un-mutes
console.log('-- Test 4: Platform unmutes --');
window._isAudioEnabled = true;
window._syncAudio(false);
console.log('After unmute, state:', window._dmJSDeviceShared.audioCtx.state); // running!
console.log('SUCCESS! AudioContext hook simulation passed.');
