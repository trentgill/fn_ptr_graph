module DSP where

{-# LANGUAGE ForeignFunctionInterface #-}

import Foreign.Ptr
import Foreign.C.Types
import Foreign.C.String
import Foreign.Storable
import FTypes

-- Gather info about DSP environment
foreign import ccall "dsp_block.h hs_dspInit"
    c_dspInit :: CString

dspInit :: IO [ModAvailable]
dspInit = do
    list <- findFns c_dspInit []
    return list
    where
        done :: String -> Bool
        done [] = True
        done _  = False
        findFns :: CString -> [ModAvailable] -> IO [ModAvailable]
        findFns ptr list = do
            str <- peekCString ptr
            fp <- peek (castPtr $ plusPtr ptr 16)
            if (done str)
                then return list
                else findFns (plusPtr ptr 24) ((str,fp):list)


foreign import ccall "dsp_block.h hs_dspCreateMod"
    c_dspCreateMod :: ModInitFn -> ModInstance

dspCreateMod :: ModAvailable -> ModInstance
dspCreateMod = c_dspCreateMod . snd


foreign import ccall "dsp_block.h hs_dspGetIns"
    c_dspGetIns :: ModInstance -> Ptr CInt


dspGetIns :: ModInstance -> IO [ModIns]
dspGetIns p = do
    let pay = (c_dspGetIns p)
    count <- peek pay
    ppp  <- peek $ plusPtr pay 8
    list <- getIns (ppp) (fromIntegral count) []
    return list
    where
        getIns :: Ptr () -> Integer -> [ModIns] -> IO [ModIns]
        getIns p 0 list = return list
        getIns p c list = do
            str <- peekCString (plusPtr p 8)
            getIns (plusPtr p 24) (c-1) ((str,p):list)


foreign import ccall "dsp_block.h hs_dspGetParams"
    c_dspGetParams :: ModInstance -> Ptr CInt

dspGetParams :: ModInstance -> IO [ModParams]
dspGetParams p = do
    let pay = (c_dspGetParams p)
    count <- peek pay
    ppp  <- peek $ plusPtr pay 8
    list <- getParams (ppp) (fromIntegral count) []
    return list
    where
        getParams :: Ptr () -> Integer -> [ModParams] -> IO [ModParams]
        getParams p 0 list = return list
        getParams p c list = do
            str <- peekCString ( plusPtr p 16 )
            getParams (plusPtr p 32)
                      (c-1)
                      ( ( str
                        , castPtrToFunPtr p
                        , castPtrToFunPtr (plusPtr p 8)
                        ) : list)


foreign import ccall "dsp_block.h hs_dspPatch"
    c_dspPatch :: ModInstance -> CInt -> ModInstance -> CInt -> CInt

dspPatch :: ModInstance -> CInt -> ModInstance -> CInt -> CInt
dspPatch = c_dspPatch



-- old
foreign import ccall "dsp_block.h hs_list"
    c_list :: Ptr CInt

foreign import ccall "dsp_block.h hs_resolve"
    c_resolve :: Ptr CInt -> CInt

dspList :: Integer
dspList = fromIntegral $ c_resolve c_list
