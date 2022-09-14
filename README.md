# repo_viewer

A new Flutter project.

# build runner command
flutter pub run build_runner watch --delete-conflicting-outputs

## Workflow 
1 - SETUP
  1.1. - Clean Yaml and add dependencies (see comments in .yaml)
  1.2. - Add custom linting rules to analysis_options.yaml - Helps ensure we use immutable state etc..

2 - Setting up the Auth App
  2.1. - Create an Oauth app on github
  2.2. - Generate a personal access token for testing purposes
  2.3. - Setup github.rest file

# Folder Structure
The simplest way to explain the folder structure is like this :- <br /><br />

1. The lib folder is divided into numerous features of the app, each having a folder of their own.
2. The files that are common between other features are stored in a "shared" folder. This generally contains the providers and any mathematical/logical/analytical codes that will help us ease our work.
3. The "core" folder contains files that are not specific to any feature/sub-feature. Generally this contains the files that can be used in multiple files to refactor them.
4. Every feature has it's own "shared" folder, although there's no such folder at the same level as other features, unlike the core.
5. Every feature has these layers -
  - domain layer: It basically contains the entities that we get from the API along with the files describing the type of failures.
  - infrastructure layer: Here we work with the APIs, databases, dto (data transfer objects) and variants (if required). Basically this is the backend of our application. Here, we call APIs or get data from databases first. Then we convert the data into dart file (if it isn't dart, usually it's json) and return them.
  - application layer: In here we create the state variants which are used by the presentation layer to display the data dynamically (declarative style coding). We call the methods of the infrastructure layer from here itself, and modify the state variants as per the value.
  - presentation layer: This is where we create the UI, pages and widgets of this feature. It only accesses the application layer.

