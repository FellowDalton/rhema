# Rhema App Firebase Backend

## Project Overview

The Rhema App is a web application designed to provide a safe, focused space for users to explore hearing the voice of God together. It aims to replace the use of Facebook groups and Messenger for this purpose, eliminating distractions and limitations of those platforms.

## Project Structure and File Descriptions

### /functions
This directory contains all the Firebase Cloud Functions for the Rhema App.

#### /src
The source code for all Cloud Functions.

##### index.js
The main entry point for all Cloud Functions. It initializes the Firebase app, sets up Express middleware, and exports all the function endpoints.

##### /config
Contains configuration files for the project.

- **firebase.js**: Initializes and exports Firebase services (Firestore, Auth, etc.).

##### /controllers
Contains the business logic for handling requests and responses.

- **prayerController.js**: Handles creation, retrieval, updating, and deletion of prayers.
- **impressionController.js**: Manages the creation and retrieval of impressions, including count for hidden prayers.
- **commentController.js**: Handles the creation and retrieval of comments after the prayer period closes.
- **feedbackController.js**: Manages the addition and retrieval of feedback by prayer creators.
- **userController.js**: Handles user profile management and dashboard data retrieval.
- **groupController.js**: Manages group creation, member addition/removal, and group-related operations.
- **notificationController.js**: Handles sending and managing notifications.

##### /models
Defines the data models and database interactions.

- **prayer.js**: Defines the prayer schema and database operations.
- **impression.js**: Defines the impression schema and related database operations.
- **comment.js**: Defines the comment schema and related database operations.
- **feedback.js**: Defines the feedback schema and related database operations.
- **user.js**: Defines the user schema and user-related database operations.
- **group.js**: Defines the group schema and group-related database operations.
- **notification.js**: Defines the notification schema and related database operations.

##### /routes
Defines the API routes for the application.

- **prayerRoutes.js**: Defines routes for prayer-related endpoints.
- **impressionRoutes.js**: Defines routes for impression-related endpoints.
- **commentRoutes.js**: Defines routes for comment-related endpoints.
- **feedbackRoutes.js**: Defines routes for feedback-related endpoints.
- **userRoutes.js**: Defines routes for user-related endpoints.
- **groupRoutes.js**: Defines routes for group-related endpoints.

##### /middleware
Contains custom middleware functions.

- **auth.js**: Handles authentication and authorization for protected routes.
- **roleCheck.js**: Verifies user roles for operations requiring specific permissions.

##### /services
Contains additional services used across the application.

- **notificationService.js**: Handles the logic for sending notifications to users.
- **dashboardService.js**: Manages the retrieval and organization of data for user dashboards.

#### package.json
Defines the project dependencies and scripts.

#### eslint.config.js
Configuration file for ESLint, defining coding style and rules.

### firebase.json
Configuration file for Firebase, defining project settings and deployment targets.

### .firebaserc
Specifies the Firebase project ID for deployment.

## Key Features

1. Prayer Management: Create, read, update, and delete prayers with visibility settings and time frames.
2. Impression System: Allow users to add impressions to open prayers, with special handling for hidden prayers.
3. Comment System: Enable users to comment on prayers after the prayer period closes.
4. Feedback Feature: Allow prayer creators to add feedback, including responses from prayer subjects.
5. User Management: Handle user authentication, profile management, and personalized dashboards.
6. Group Functionality: Create and manage prayer groups with controlled membership.
7. Notification System: Send notifications for prayer updates, new impressions, comments, and feedback.

This structure provides a scalable and modular backend for the Rhema App, allowing for easy expansion and maintenance of features. The separation of concerns between controllers, models, and routes ensures a clean and maintainable codebase.

## Getting Started

1. Clone the repository
2. Install dependencies with `npm install`
3. Set up your Firebase project and update the configuration in `src/config/firebase.js`
4. Run the development server with `npm run serve`
5. Deploy to Firebase with `npm run deploy`

For more detailed instructions on setting up and deploying Firebase functions, please refer to the [Firebase documentation](https://firebase.google.com/docs/functions).

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
