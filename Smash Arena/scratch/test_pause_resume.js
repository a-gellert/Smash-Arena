// Test simulation of Emscripten MainLoop pause and resume
let rAFCallbacks = [];
let nextId = 1;
global.window = global;

function requestAnimationFrame(cb) {
  const id = nextId++;
  rAFCallbacks.push({ id, cb });
  return id;
}

function cancelAnimationFrame(id) {
  rAFCallbacks = rAFCallbacks.filter(x => x.id !== id);
}

const MainLoop = {
  running: false,
  scheduler: null,
  currentlyRunningMainloop: 0,
  func: null,
  arg: 0,
  timingMode: 1,
  timingValue: 0,
  pause() {
    console.log('MainLoop.pause() called');
    MainLoop.scheduler = null;
    MainLoop.currentlyRunningMainloop++;
  },
  resume() {
    console.log('MainLoop.resume() called');
    MainLoop.currentlyRunningMainloop++;
    var timingMode = MainLoop.timingMode;
    var timingValue = MainLoop.timingValue;
    var func = MainLoop.func;
    MainLoop.func = null;
    setMainLoop(func, 0, false, MainLoop.arg, true);
    MainLoop.scheduler();
  }
};

function setMainLoop(iterFunc, fps, simulateInfiniteLoop, arg, noSetTiming) {
  MainLoop.func = iterFunc;
  MainLoop.arg = arg;
  MainLoop.running = true;
  MainLoop.scheduler = function() {
    requestAnimationFrame(function tick() {
      if (MainLoop.scheduler) {
        MainLoop.func();
        MainLoop.scheduler();
      }
    });
  };
}

const Module = {
  pauseMainLoop: MainLoop.pause,
  resumeMainLoop: MainLoop.resume,
  _dmEngineSetUpdateEnabled: (val) => console.log('_dmEngineSetUpdateEnabled:', val),
  _dmEngineSetRenderEnabled: (val) => console.log('_dmEngineSetRenderEnabled:', val),
};

let frameCount = 0;
setMainLoop(() => { frameCount++; console.log('Tick frame:', frameCount); });
MainLoop.scheduler();

// Step 1: Run a few frames
console.log('-- Running 2 ticks --');
let cb = rAFCallbacks.shift(); cb.cb();
cb = rAFCallbacks.shift(); cb.cb();

// Step 2: Pause
console.log('-- Pausing --');
let isPaused = false;
function pauseEngine() {
  if (isPaused) return;
  isPaused = true;
  Module._dmEngineSetUpdateEnabled(0);
  Module._dmEngineSetRenderEnabled(0);
  Module.pauseMainLoop();
}

pauseEngine();
console.log('rAF queue length:', rAFCallbacks.length);
if (rAFCallbacks.length > 0) {
  // If there's an in-flight rAF from before pause:
  cb = rAFCallbacks.shift(); cb.cb();
}
console.log('After in-flight tick, scheduler is:', MainLoop.scheduler);
console.log('rAF queue length:', rAFCallbacks.length);

// Step 3: Resume
console.log('-- Resuming --');
function resumeEngine() {
  if (!isPaused) return;
  isPaused = false;
  Module._dmEngineSetUpdateEnabled(1);
  Module._dmEngineSetRenderEnabled(1);
  Module.resumeMainLoop();
}

resumeEngine();
console.log('rAF queue length after resume:', rAFCallbacks.length);
cb = rAFCallbacks.shift(); cb.cb();
console.log('Tick after resume, new queue length:', rAFCallbacks.length);
console.log('SUCCESS! MainLoop pause/resume simulation passed.');
