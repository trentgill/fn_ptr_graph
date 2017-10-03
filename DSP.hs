module DSP where

{-# LANGUAGE ForeignFunctionInterface #-}

import Foreign.Ptr
import Foreign.C.Types
import Foreign.Storable

foreign import ccall "dsp_block.h hs_list"
    c_list :: Ptr CInt

foreign import ccall "dsp_block.h hs_resolve"
    c_resolve :: Ptr CInt -> CInt

dspList :: Integer
dspList = fromIntegral $ c_resolve c_list
