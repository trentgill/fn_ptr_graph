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
    mlist <- findAvailMods (struct ) []
    return ( mlist, ([], []))

isEmptyString :: String -> Bool
isEmptyString [] = True
isEmptyString _  = False

findAvailMods :: Ptr () -> [ModAvailable] -> IO [ModAvailable]
findAvailMods ptr list = do
    str <- peekCString $ castPtr ptr
    fp <- peek (castPtr $ plusPtr ptr 16)
    if (isEmptyString str)
        then return list
        else findAvailMods (plusPtr ptr 24)
                           ((str,fp) : list )

foreign import ccall "dsp_block.h hs_dspCreateMod"
    c_dspAllocMod :: FunPtr () -> Ptr ()

dspCreateMod :: ModAvailable -> IO ActiveMod
dspCreateMod m = return $ ActiveMod
    { mtype     = fst m
    , mindex    = 0 -- needs to be set by environment
    , address   = c_dspAllocMod $ snd m
    , ins       = ("in",nullPtr):[]
    , params    = []
    , outs      = ("out",nullPtr):[]
    }

-- DSPEnvironment helpers
patch_op :: ([ActivePatch] -> [ActivePatch])
         -> DSPEnvironment
         -> DSPEnvironment
patch_op fn (l, (am, ap)) = (l, (am, fn ap))

mod_op :: ([ActiveMod] -> [ActiveMod])
         -> DSPEnvironment
         -> DSPEnvironment
mod_op fn (l, (am, ap)) = (l, (fn am, ap))


-- haskell only fn
dspPatch :: DSPEnvironment
         -> ActiveMod
         -> ModOut
         -> ActiveMod
         -> ModIn
         -> DSPEnvironment
dspPatch env s so d di = patch_op(fn s so d di) env
    where
        fn s so d di pl = ((1 + length pl),(s,so),(d,di)):pl

-- old
foreign import ccall "dsp_block.h hs_list"
    c_list :: Ptr CInt

foreign import ccall "dsp_block.h hs_resolve"
    c_resolve :: Ptr CInt -> CInt

dspList :: Integer
dspList = fromIntegral $ c_resolve c_list
