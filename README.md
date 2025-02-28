StateTransfer is a small tool to perform REST (Representational State Transfer) requests. The purpose is to test API calls prior to implementing them in your software. It also helps debugging when creating new APIs.


* Supports the standard HTTP methods.
* Allows you to set the HTTP request headers.
* Allows you to set request parameters and will format them depending on the request type.
* Supports sending parameters as either form-encoded or json-encoded.
* Supports basic HTTP authentication.
* Supports Keychain for credential storrage.
* X/HTML and JSON responses can be pretty-printed.
* Requests can be exported as curl-Command, Swift source code or .http files.

Download it either [here on GitHub](https://github.com/holgerkrupp/StateTransfer/releases) or on the [Mac App Store](https://apps.apple.com/de/app/statetransfer-a-rest-client/id6742325165?l=en-GB&mt=12).

The tool was created after "[RESTed](https://www.helloresolven.com/portfolio/rested/)" has been removed from the App Store. The current Version of StateTransfer is not feature complete. StateTransfer can read part of RESTed files (\*.request). 

When launching the app you can open an existing or create a new HTTP Request Session. You can import Files created with RESTed.
![App Launch Window](https://github.com/holgerkrupp/StateTransfer/blob/main/Screenshots/App%20Store.png?raw=true)


The all allows you to define API Endpoints/URLs, headers, parameters and body. Basic HTTP Authentication is supported. When submitting the request, you will be able to analyize the Server answer on the right side of the main window. You can also copy a corresponding CURL command or even Swift Source code to the clipboard.
![Main Window](https://github.com/holgerkrupp/StateTransfer/blob/main/Screenshots/App%20Store%202.png?raw=true)
