{-# LANGUAGE ApplicativeDo, FlexibleContexts, OverloadedStrings,
  RecordWildCards, ScopedTypeVariables #-}

import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Monad (forever)
import Data.Aeson
import Data.Maybe (fromMaybe)
import Data.Default (def)
import qualified Data.BloomFilter as Bloom (fromList)
import Data.BloomFilter.Hash (cheapHashes)
import qualified Data.ByteString.Lazy.Char8 as LBS8 (readFile)
import Options.Applicative

import Brockman.Bot
import Brockman.Types
import Brockman.Util

brockmanOptions :: Parser BrockmanOptions
brockmanOptions = do
  configFile <- strArgument $ metavar "CONFIG-PATH" <> help "config file path"
  ircHost <- strArgument $ metavar "IRC-HOST" <> help "IRC server address"
  ircPort <-
    option auto $
    long "port" <> short 'p' <> metavar "PORT" <> help "IRC server port" <>
    value 6667 <>
    showDefault
  shortener <-
    optional $
    strOption $
    long "shortener" <> metavar "URL" <> help "feed link shortener" <>
    value "http://go" <>
    showDefault
  useTLS <- switch $ long "ssl" <> help "use TLS/SSL"
  pure BrockmanOptions {..}

main :: IO ()
main = do
  options <-
    execParser $
    info
      (helper <*> brockmanOptions)
      (fullDesc <> progDesc "Broadcast RSS feeds to IRC")
  config@BotsConfig {..} <-
    fromMaybe def . decode <$> LBS8.readFile (configFile options)
  let bloom0 = Bloom.fromList (cheapHashes 17) (2 ^ 10 * 1000) [""]
  bloom <- atomically $ newTVar bloom0
  forConcurrently_ configBots $ \bot ->
    eloop $ botThread bloom bot config options
  forever $ sleepSeconds 1