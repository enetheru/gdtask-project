```gdscript
#   ██████  ██████  ████████  █████  ███████ ██   ██
#  ██       ██   ██    ██    ██   ██ ██      ██  ██
#  ██   ███ ██   ██    ██    ███████ ███████ █████
#  ██    ██ ██   ██    ██    ██   ██      ██ ██  ██
#   ██████  ██████     ██    ██   ██ ███████ ██   ██
# 
# ███████████████████████████████████████████████████
```

Task object inspired by UniTask

## Motivation

I just wanted a nice interface for creating tasks that I was used to from
UniTask, so I thought how hard can it be to just whip something up for myself.

Its probably trash level code, but so long as it works for me thats ok.

## Features

* Written entirely within gdscript
* GDTask object
    - Cancellable
    - Resettable
    - run async, or sync
    - Then
* Additional Class Specialisations for:
    - delayed run
    - wait until 
    - repetition
    - repetition
    - Timeout
* Tests

## Specialisations

### WaitUntil

I want to wait until a signal is triggered
I want to wait until a value is true
I want to wait until a function returns true.
Then  I can do something.

The task itself would either be a hold on a function till some predicate described above, or it would start the chain,
Like:

```gdscript
GDTask.WaitUntil( predicate ).then( secondary task )
```

### RepeatFor
A task that repeats on a timed interval, for a set number of times, or endlessly

What about repeating until a predicate is reached, so RepeatUntil.
It sounds like I want to add a predicate for the cancel function like
CancelWhen( predicate )
CancelOn( signal )


ascii titles generated using: http://www.patorjk.com/software/taag

## Wishlist

WhenAll( [] )

WhenAny( [] )

RPC

editor manager node with panel
