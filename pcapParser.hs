import Control.Monad
import Data.Binary
import Data.Binary.Get
import qualified Data.ByteString as Strict
import qualified Data.ByteString.Char8 as CS
import qualified Data.ByteString.Lazy.Char8 as Lazy
import qualified Data.ByteString.Lazy.Internal as LI
import qualified Data.ByteString.Lazy as L

data Header = Header { magic :: Strict.ByteString
                     , version :: Strict.ByteString
                     , timezone :: Strict.ByteString
                     , accuracy :: Strict.ByteString
                     , snapshot :: Strict.ByteString
                     , linklayer :: Strict.ByteString
                     } deriving (Show)

data Bids = Bids  
  {priceBid :: !Strict.ByteString, qtyBid :: !Strict.ByteString}  
  deriving (Show)



data TradeJoe = Nada | TradeJoe
  { packetTime :: !Int
  , quoteAccept :: !Strict.ByteString
  , issueCode      :: !Strict.ByteString
  , bids     :: ![Bids]
  , asks       :: ![Bids]
  } deriving (Show)

data TradeJoe3 = Nil | TradeJoe3
  { packetLen :: !Int
  } deriving (Show)

getHeader = do
          magic <- getByteString 4
          version <- getByteString 4
          timezone <- getByteString 4
          accuracy <- getByteString 4
          snapshot <- getByteString 4
          linklayer <- getByteString 4
          rest <- getRemainingLazyByteString
          return (Header magic version timezone accuracy snapshot linklayer,rest)

getTestByteString = do
  test <- getByteString (58+212+58+215+58+215+58+215+58+258)
  rest <- getRemainingLazyByteString
  return (test,rest)
{--
getTradeJoe2 :: Get TradeJoe
getTradeJoe2 = do
  --skip 58
  skip 12
  packetLength <- getWord32le
  skip 5
  issueCode <- getByteString 12
  skip 12
  bids <- replicateM 5 getX
  skip 7
  asks <- replicateM 5 getX
  skip (5 + 5*4 + 5 + 5*4)
  quoteAccept <- getByteString 8
  skip 1
  return $! TradeJoe quoteAccept issueCode bids asks 
--}
getTradeJoe3 = do
   secondsFrom <- (fromIntegral <$> getWord32le) -- the number of seconds since unix time.
   microSecs   <- (fromIntegral <$> getWord32le) -- followed by microseconds 
   skip 4 --skip the first 4 from the pre packet part, (pre packet is 58 in length)
   packetLen <- (fromIntegral <$> getWord32le) --getting the packet size(<$>) :: Functor f => (a->b) -> f a -> f b
   skip (58-12-4)
   if ((packetLen-42) == 215)
     then do
     skip 5 -- skip the packet header, ascii B6xxx
     issueCode <- getByteString 12 -- issue code
     skip 12
     bids <- replicateM 5 getX
     skip 7
     asks <- replicateM 5 getX
     skip (5 + 5*4 + 5 + 5*4)
     quoteAccept <- (getByteString 8)
     skip 1
     return $! TradeJoe secondsFrom quoteAccept issueCode bids asks
     --return $! Nil
     --return $! TradeJoe3 packetLen
     else do
             skip (packetLen-42)
             return $! Nada
             --return $! TradeJoe3 packetLen


getX = do
  priceX <- getByteString 5
  qtyX   <- getByteString 7
  return (Bids priceX qtyX)
{--
incrementalExampleJoe :: Lazy.ByteString -> [TradeJoe]
incrementalExampleJoe input0 = gojo decoder input0
  where
    decoder = runGetIncremental getTradeJoe2
    gojo :: Decoder TradeJoe -> Lazy.ByteString -> [TradeJoe]
    gojo (Done leftover _consumed trade) input =      trade : gojo decoder (LI.chunk leftover input)
    gojo (Partial k) input                     =      gojo (k . takeHeadChunk $ input) (dropHeadChunk input)
    gojo (Fail leftover _consumed msg) input =      error msg
--}  
incrementalExampleJoe3 :: Lazy.ByteString -> [TradeJoe]
incrementalExampleJoe3 input0 = gojo decoder input0
  where
    decoder = runGetIncremental getTradeJoe3
    gojo :: Decoder TradeJoe -> Lazy.ByteString -> [TradeJoe]
    gojo (Done leftover _consumed trade) input =      trade : gojo decoder (LI.chunk leftover input)
    gojo (Partial k) input                     =      gojo (k . takeHeadChunk $ input) (dropHeadChunk input)
    gojo (Fail leftover _consumed msg) input =      error msg
  
takeHeadChunk :: LI.ByteString -> Maybe CS.ByteString
takeHeadChunk lbs =
  case lbs of
    (LI.Chunk bs _) -> Just bs
    _ -> Nothing

dropHeadChunk :: LI.ByteString -> LI.ByteString
dropHeadChunk lbs =
  case lbs of
    (LI.Chunk  _ lbs') -> lbs'
    _ -> Lazy.empty



main :: IO ()
main = do
  src <- Lazy.readFile ("mdf-kospi200.20110216-0.pcap")
  let (header,rest) = runGet getHeader src
  --let (test,rest') = runGet getTestByteString rest
  --let joe3 = incrementalExampleJoe rest
  let joeTrade3 = incrementalExampleJoe3 rest
  print (joeTrade3)
