module DSP where

{-# LANGUAGE ForeignFunctionInterface #-}

import Foreign.Ptr
import Foreign.C.Types
import Foreign.C.String
import Foreign.Storable
import FTypes

-- Gather info about DSP environment
foreign import ccall "dsp_block.h hs_dspInit"
    c_dspInit :: Ptr ()

dspInit :: IO DSPEnvironment
dspInit = do
    let struct = c_dspInit
    mlist <- findAvailMods struct []
    return (mlist, ModGraph { actMods    = []
                            , actPatches = []
                            , recompile  = False
                            })

findAvailMods :: Ptr () -> [ModAvailable] -> IO [ModAvailable]
findAvailMods ptr list = do
    str <- peekCString $ castPtr ptr
    fp <- peek (castPtr $ plusPtr ptr 16)
    if (null str)
        then return list
        else findAvailMods (plusPtr ptr 24)
                           ((str,fp) : list )


-- DSPEnvironment helpers
patch_op :: DSPEnvironment
         -> ([ActivePatch] -> [ActivePatch])
         -> DSPEnvironment
patch_op (l, graph) fn
    = (l, graph { actPatches = fn (actPatches graph)
                , recompile  = True
                })

mod_op :: DSPEnvironment
       -> ([ActiveMod] -> [ActiveMod])
       -> DSPEnvironment
mod_op (l, graph) fn
    = (l, graph { actMods = fn (actMods graph) })


-- Allocate a new module & it to the Runtime Env
foreign import ccall "dsp_block.h hs_dspCreateMod"
    c_dspAllocMod :: FunPtr () -> IO (Ptr())

dspCreateMod :: DSPEnvironment
             -> ModAvailable
             -> IO DSPEnvironment
dspCreateMod env m = do
    newMod <- makeMod m (lastMod env)
    return $ mod_op env (newMod :)
    where
        lastMod :: DSPEnvironment -> Int
        lastMod (_, g@(ModGraph {actMods=[]})) = 0
        lastMod (_, g) = mindex (head $ actMods g)
        makeMod :: ModAvailable -> Int -> IO ActiveMod
        makeMod m c = return $
            ActiveMod { mtype     = fst m
                      , mindex    = c + 1
                      , address   = c_dspAllocMod $ snd m
                      , ins       = ("in",nullPtr):[]
                      , params    = []
                      , outs      = ("out",nullPtr):[]
                      }

-- haskell only fn
dspPatch :: DSPEnvironment
         -> ActiveMod
         -> ModOut
         -> ActiveMod
         -> ModIn
         -> DSPEnvironment
dspPatch env s so d di = patch_op env (fn s so d di)
    where
        fn s so d di pl = ((1 + length pl),(s,so),(d,di)):pl


-- and here's the DSP compiler!!
-- it really just calls some C hooks
-- but the decision of *which* hooks to call is the hard part!
dsp_recompile :: DSPEnvironment
              -> IO DSPEnvironment
dsp_recompile (l, e@(ModGraph {recompile=False})) = return (l, e)
dsp_recompile (l, e) = do -- this is the compiler
    return (l, e { recompile = False })

    -- traverse the active patches starting with IO
    -- work from dest->source (backward) until 
    --
    --
    --
    --
    --
    --
    --
