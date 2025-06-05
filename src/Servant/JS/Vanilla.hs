{-#LANGUAGE OverloadedStrings #-}
module Servant.JS.Vanilla where

import Prelude ()
import Prelude.Compat

import           Control.Lens
import           Data.Maybe (isJust)
import           Data.Text (Text)
import           Data.Text.Encoding (decodeUtf8)
import qualified Data.Text as T
import           Servant.Foreign hiding (header)
import           Servant.JS.Internal

-- | Generate vanilla javascript functions to make AJAX requests
--   to your API, using /XMLHttpRequest/. Uses 'defCommonGeneratorOptions'
--   for the 'CommonGeneratorOptions'.
vanillaJS :: JavaScriptGenerator
vanillaJS = mconcat . map generateVanillaJS

-- | Generate vanilla javascript functions to make AJAX requests
--   to your API, using /XMLHttpRequest/. Lets you specify your
--   own options.
vanillaJSWith :: CommonGeneratorOptions -> JavaScriptGenerator
vanillaJSWith opts = mconcat . map (generateVanillaJSWith opts)

-- | js codegen using XmlHttpRequest using default generation options
generateVanillaJS :: AjaxReq -> Text
generateVanillaJS = generateVanillaJSWith defCommonGeneratorOptions

-- | js codegen using XmlHttpRequest
generateVanillaJSWith :: CommonGeneratorOptions -> AjaxReq -> Text
generateVanillaJSWith opts req = "\n" <>
    fname <> " = function(" <> argsStr <> ") {\n"
 <> "  var xhr = new XMLHttpRequest();\n"
 <> "  xhr.open('" <> decodeUtf8 method <> "', " <> url <> ", true);\n"
 <>    reqheaders
 <> "  xhr.setRequestHeader('Accept', 'application/json');\n"
 <> (if isJust (req ^. reqBody) && (req ^. _reqBodyContentType == ReqBodyJSON)  then "  xhr.setRequestHeader('Content-Type', 'application/json');\n" else "")
 <> "  xhr.onreadystatechange = function () {\n"
 <> "    var res = null;\n"
 <> "    if (xhr.readyState === 4) {\n"
 <> "      if (xhr.status === 204 || xhr.status === 205) {\n"
 <> "        " <> onSuccess <> "();\n"
 <> "      } else if (xhr.status >= 200 && xhr.status < 300) {\n"
 <> "        try { res = JSON.parse(xhr.responseText); } catch (e) { " <> onError <> "(e); }\n"
 <> "        if (res) " <> onSuccess <> "(res);\n"
 <> "      } else {\n"
 <> "        try { res = JSON.parse(xhr.responseText); } catch (e) { " <> onError <> "(" <>
                (if ignoreErrorParsingErrors opts then "xhr.responseText" else "e") <> "); }\n"
 <> "        if (res) " <> onError <> "(res);\n"
 <> "      }\n"
 <> "    }\n"
 <> "  };\n"
 <> "  xhr.send(" <> dataBody <> ");\n"
 <> "};\n"

  where argsStr = T.intercalate ", " args
        args = captures
            ++ map (view $ queryArgName . argPath) queryparams
            ++ body
            ++ map ( toValidFunctionName
                   . (<>) "header"
                   . view (headerArg . argPath)
                   ) hs
            ++ [onSuccess, onError]

        captures = map (view argPath . captureArg)
                 . filter isCapture
                 $ req ^. reqUrl.path

        hs = req ^. reqHeaders

        queryparams = req ^.. reqUrl.queryStr.traverse

        body = if isJust(req ^. reqBody)
                 then [requestBody opts]
                 else []

        onSuccess = successCallback opts
        onError = errorCallback opts

        dataBody =
          if isJust (req ^. reqBody)
            then if (req ^. _reqBodyContentType == ReqBodyJSON) then "JSON.stringify(body)" else "body"
            else "null"


        reqheaders =
          if null hs
            then ""
            else headersStr <> "\n"

          where
            headersStr = T.intercalate "\n" $ map headerStr hs
            headerStr header = "  xhr.setRequestHeader(\"" <>
              header ^. headerArg . argPath <>
              "\", " <> toJSHeader header <> ");"

        namespace = if moduleName opts == ""
                       then "var "
                       else (moduleName opts) <> "."
        fname = namespace <> (toValidFunctionName (functionNameBuilder opts $ req ^. reqFuncName))

        method = req ^. reqMethod
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
