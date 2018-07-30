{-# LANGUAGE OverloadedStrings #-}
module Servant.JS.Fetch where

import           Control.Lens
import           Data.Maybe          (isJust)
import           Data.Monoid         ((<>))
import           Data.Text           (Text)
import qualified Data.Text           as T
import           Data.Text.Encoding  (decodeUtf8)
import           Servant.Foreign
import           Servant.JS.Internal

data ModeOpts =
    ModeNotSpecified
  | Navigate
  | Cors 
  | NoCors 
  | SameOrigin

instance Show ModeOpts where
  show ModeNotSpecified = ""
  show Navigate = "navigate"
  show Cors = "cors"
  show NoCors = "no-cors"
  show SameOrigin = "same-origin"

data CacheOpts = 
    CacheNotSpecified 
  | Default  
  | NoStore
  | Reload
  | NoCache
  | ForceCache
  | OnlyIfCached

instance Show CacheOpts where
  show CacheNotSpecified = ""
  show Default = "default"
  show NoStore = "no-store"
  show Reload = "reload"
  show NoCache = "no-cache"
  show ForceCache = "force-cache"
  show OnlyIfCached = "only-if-cached"
      
data CredentialOpts =
    CredentialNotSpecified
  | Omit
  | Include
  | SameOriginCredential

instance Show CredentialOpts where
  show CredentialNotSpecified = ""
  show Omit = "omit"
  show Include = "include"
  show SameOriginCredential = "same-origin"

-- | Fetch 'configuration' type
-- Let you customize the generation using Fetch capabilities
data FetchOptions = FetchOptions
  { -- allows setting mode for cors 
    mode :: !ModeOpts
  -- allows specifying caching policy
  , cache :: !CacheOpts
  -- allows setting wether credentials should be sent with request
  , credential :: !CredentialOpts
  }

instance Show CommonGeneratorOptions
-- | Default instance of the FetchOptions
-- Defines the settings as they are in the Fetch documentation
-- by default
defFetchOptions :: FetchOptions
defFetchOptions = FetchOptions
  { mode = ModeNotSpecified
  , cache = CacheNotSpecified
  , credential = CredentialNotSpecified
  }

-- | Generate regular javacript functions that use
--   the fetch library, using default values for 'CommonGeneratorOptions'.
fetch :: FetchOptions -> JavaScriptGenerator
fetch aopts = fetchWith aopts defCommonGeneratorOptions

-- | Generate regular javascript functions that use the fetch library.
fetchWith :: FetchOptions -> CommonGeneratorOptions -> JavaScriptGenerator
fetchWith aopts opts = T.intercalate "\n" . map (generateFetchJSWith aopts opts)

-- | js codegen using fetch library using default options
generateFetchJS :: FetchOptions -> AjaxReq -> Text
generateFetchJS aopts = generateFetchJSWith aopts defCommonGeneratorOptions


-- | js codegen using fetch library
generateFetchJSWith :: FetchOptions -> CommonGeneratorOptions -> AjaxReq -> Text
generateFetchJSWith aopts opts req =
    fname <> " = function(" <> argsStr <> ") {\n"
 <> "  return fetch(" <> url <>", {\n"
 <> "    method: '" <> method <> "',\n"
 <> dataBody
 <> reqheaders
 <> withMode
 <> withCache
 <> withCreds
 <> "  });\n"
 <> "};\n"

  where argsStr = T.intercalate ", " args
        args = captures
            ++ map (view $ queryArgName . argPath) queryparams
            ++ body
            ++ map ( toValidFunctionName
                   . (<>) "header"
                   . view (headerArg . argPath)
                   ) hs

        captures = map (view argPath . captureArg)
                 . filter isCapture
                 $ req ^. reqUrl.path

        hs = req ^. reqHeaders

        queryparams = req ^.. reqUrl.queryStr.traverse

        hasBody = isJust (req ^. reqBody)

        body = [requestBody opts | hasBody]

        dataBody =
          if hasBody
            then "    data: JSON.stringify(body),\n" 
            else ""

        withMode = 
          let modeType = mode aopts in 
          case modeType of 
            ModeNotSpecified -> ""
            _ -> "    mode: "<> (T.pack . show) modeType <> ",\n"

        withCache = 
          let cacheType = cache aopts in 
          case cacheType of 
            CacheNotSpecified -> ""
            _ -> "    cache: "<> (T.pack . show) cacheType <> ",\n"

        withCreds =
          let credType = credential aopts in 
          case credType of
            CredentialNotSpecified -> ""
            _ -> "    credentials: "<> (T.pack . show) credType <> ",\n"

        reqBodyHeader = "\"Content-Type\": \"application/json; charset=utf-8\""

        reqheaders =
          if null hs
            then if hasBody
              then "    headers: { " <> headersStr (reqBodyHeader : generatedHeader) <> " },\n"
              else ""
            else "    headers: { " <> headersStr generatedHeader <> " },\n"

          where
            headersStr = T.intercalate ", " 
            generatedHeader = map headerStr hs
            headerStr header = "\"" <>
              header ^. headerArg . argPath <>
              "\": " <> toJSHeader header

        namespace =
               if hasNoModule
                  then "var "
                  else moduleName opts <> "."
               where
                  hasNoModule = moduleName opts == ""

        fname = namespace <> toValidFunctionName (functionNameBuilder opts $ req ^. reqFuncName)

        method = T.toLower . decodeUtf8 $ req ^. reqMethod
        url = if url' == "'" then "'/'" else url'
        url' = "'"
           <> urlPrefix opts
           <> urlArgs
           <> queryArgs

        urlArgs = jsSegments
                $ req ^.. reqUrl.path.traverse

        queryArgs = if null queryparams
                      then ""
                      else " + '?" <> jsParams queryparams
