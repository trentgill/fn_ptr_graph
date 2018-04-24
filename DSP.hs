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
    putStrLn("newMod")
    return $ mod_op env (newMod :)
    where
        lastMod :: DSPEnvironment -> Int
        lastMod (_, g@(ModGraph {actMods=[]})) = 0
        lastMod (_, g) = mindex (head $ actMods g)
        makeMod :: ModAvailable -> Int -> IO ActiveMod
        makeMod m c = do
            let amod = ActiveMod { mtype     = fst m
                                 , mindex    = c + 1
                                 , address   = c_dspAllocMod $ snd m
                                 , ins       = ("in",nullPtr):[]
                                 , params    = []
                                 , outs      = []
                                 }
            newAddr <- address amod
            newOuts <- discoverOuts newAddr 0
            return (amod { outs = newOuts })

-- helper functions to get info from module_t* box
foreign import ccall "dsp_block.h hs_dspGetOutCount"
    c_dspGetOutCount :: Ptr() -> (CInt)
foreign import ccall "dsp_block.h hs_dspGetOut"
    c_dspGetOut :: Ptr() -> Int -> Ptr()

discoverOuts :: Ptr() -> Int -> IO [ModOut]
discoverOuts ptr count = do
    if count >= (fromIntegral $ c_dspGetOutCount ptr)
        then return $ []
        else do
            tOut <- dspThisOut ptr count
            nOuts <- discoverOuts ptr (count+1)
            return $ tOut : nOuts
    where
        dspThisOut :: Ptr() -> Int -> IO ModOut
        dspThisOut p i = do
            let addr = c_dspGetOut p i
            str <- peekCString $ castPtr $ plusPtr addr 8
            return (str, castPtr addr)
            --return("",nullPtr)


-- haskell only fn
dspPatch :: DSPEnvironment
         -> ActiveMod         -- source
         -> ModOut
         -> ActiveMod         -- destination
         -> ModIn
         -> DSPEnvironment
dspPatch env s so d di = patch_op env (fn s so d di)
    where
        fn s so d di pl = ((1 + length pl),(s,so),(d,di)):pl

-- and here's the DSP compiler!!
foreign import ccall "dsp_block.h hs_patchCount"
    c_patchCount :: Int -> IO ()

-- it really just calls some C hooks
-- but the decision of *which* hooks to call is the hard part!
dsp_recompile :: DSPEnvironment
              -> IO DSPEnvironment
dsp_recompile (l, e@(ModGraph {recompile=False})) = return (l, e)
dsp_recompile (l, e) = do -- this is the compiler
    c_patchCount( length $ actPatches e )  -- tell C how many patches exist
    putStrLn("patch cnt ")
    putStrLn( show . length $ actPatches e )
    return (l, e { recompile = False })

    -- traverse the active patches starting with IO
    -- work from dest->source (backward) until no inputs
    --
        -- run a C function to change the output-destination pointer
        -- in future, any connections with multiples add a helper
        -- block which just copies buffers to multiple destinations
        -- thus the only blocks with variable # of endpoints are the
        -- helper blocks, and all dsp has standard single points
        --
        -- further, this means that 'mixpoints' can have different
        -- mix math. eg additive, min/max etc. but also more complex
        -- algos to allow limiting / saturation / compression / scaling
    --
    --
    --
    --
    --
    --
