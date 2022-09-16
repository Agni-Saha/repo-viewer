# repo_viewer

A new Flutter project.

# build runner command
```flutter pub run build_runner watch --delete-conflicting-outputs```

## Workflow 
1. Setting up the Auth App
    1. Create an Oauth app on github
    2. Generate a personal access token for testing purposes
    3. Setup github.rest file
2. Getting this code :-
    1. Copy the https clone link of this app
    2. Get all dependencies by either saving (`ctrl/cmd + c`) the pubspec.yaml file, or running this command on terminal: `flutter pub get`
    3. Create a .env file, similar to the .env.sample file created
    4. Add your client id and client secret (that you get from Github OAuth app).
3. Run the app from VSCode, or using the terminal with this command : ```flutter run```
4. Make sure to run the build command before you actually run the app for safe measure.

# Folder Structure
The simplest way to explain the folder structure is like this :-

1. The lib folder is divided into numerous features of the app, each having a folder of their own.
2. The files that are common between other features are stored in a "shared" folder. This generally contains the providers and any mathematical/logical/analytical codes that will help us ease our work.
3. The "core" folder contains files that are not specific to any feature/sub-feature. Generally this contains the files that can be used in multiple files to refactor them.
4. Every feature has it's own "shared" folder, although there's no such folder at the same level as other features, unlike the core.
5. Every feature has these layers -
    - **domain layer**: It basically contains the entities that we get from the API along with the files describing the type of failures.
    - **infrastructure layer**: Here we work with the APIs, databases, dto (data transfer objects) and variants (if required). Basically this is the backend of our application. Here, we call APIs or get data from databases first. Then we convert the data into dart file (if it isn't dart, usually it's json) and return them.
    - **application layer**: In here we create the state variants which are used by the presentation layer to display the data dynamically (declarative style coding). We call the methods of the infrastructure layer from here itself, and modify the state variants as per the value.
    - **presentation layer**: This is where we create the UI, pages and widgets of this feature. It only accesses the application layer.

## General Code flow of a feature
It's somewhat like this :-

1. The Domains are the entities that are shown in the UI.
2. The Infrastructure layer makes the API request/ Database request and get the data. It converts those data into necessary dart entities and returns either a failure or the actual data (it might not even return anything, just notifying that everything is successful is more than enough in some cases).
3. The Application Layer actually calls the Infrastruture layer and has the state variants depending upon the cases of the value returned from Infrastructure layer. It returns the state variants that has been updated.
4. The Presentation layer accesses the providers/state-managements and calls the Application Layer's methods and depending upon the variants returned by the Application Layer, it shows the UI.

# Explaining the several features :-

## Page Navigation / AppRouter
I have used Navigator 2.0 using AppRouter package to make the page navigation a lot easier. Files Location :- /lib/core/presentation <br />
The routes are created using AppRouter and stored in "routes" folder. In the AppWidget.dart, which is the entry point from main.dart, we are creating the sembast database instance, the dio instance with necessary headers and interceptors added to it, and listening to the AuthState (variants of authentication). Depending on those variants, we are either navigating the user to SignIn page or StarredRepos page.

## Authentication Feature
The core working of the oauth2 authentication from github api is like this :- we make a request to the API using the clientID, clientSecret, endpoints, redirectUrl and other things. Using this, we'll get the URL where the we can go to get ourselves authorized. After we've successfully authorized, we will receive a hash in the form of query parameter called "code" in our redirectUrl, which we will exchange to get the accessToken. In case of Github API, the access tokens donot get refreshed, meaning we can use the same access token to enter the app always, forever. <br />
In the infrastructure layer, we are creating classes that will store the credentials of the user in flutter_secure_storage. The main file that communicates with theserver and authenticates the user is github_authenticator.dart file. In that class, there are several methods created for handling the authentication, like :- 
1. getSignedInCredentials - getting the storred credentials from flutter_secure_storage (if they are even present).
2. isSignedIn - utility method that runs method of (1) and returns true or false depending on the value.
3. createGrant - method that creates a grant of OAuth2 facilitating the login process.
4. getAuthorizationUrl - returns the url of webview where the user can go to get themselves authorized.
5. handleAuthorizationResponse - exchanges the "code" query parameter with access token and saves that access token in the flutter_secure_storage.

The authentication feature flow is like this :-
- auth_notifier is the file where the variants of authentication are created and it has a signIn() method that calls the various methods of infrastructure layer to facilitate the authentication process, returning a variant based on the results.
- sign_in page calls the signIn() method of auth_notifier, passing it a callback which will get the URL of webview authentication.
- auth_notifier creates the grant, creates the url and then passes the url in that callback.
- The callback redirects the user to the authorization_page of presentation layer with the url, which uses the url to launch a webview.
- After successful authentication, the webview automatically tries to redirect the user at the redirectUrl with the "code" query parameter.
- Whenever we are getting redirected, we check if the base url is the redirectUrl or not. If it is, we extract and return the query string.
- This return is captured by the signIn() method of auth_notifier, which it uses to call the handleSuccessOrFailure() method, that simply updates the state variants based on the value returned.
- As the authentication variant changes, the AppWidget page gets notified about it and it triggers the AppRouter redirection accordingly.
