# Updated Rhema App Firebase Backend Structure

rhema-app/
├── functions/
│   ├── src/
│   │   ├── index.js
│   │   ├── config/
│   │   │   └── firebase.js
│   │   ├── controllers/
│   │   │   ├── prayerController.js
│   │   │   ├── impressionController.js
│   │   │   ├── commentController.js
│   │   │   ├── feedbackController.js
│   │   │   ├── userController.js
│   │   │   ├── groupController.js
│   │   │   └── notificationController.js
│   │   ├── models/
│   │   │   ├── prayer.js
│   │   │   ├── impression.js
│   │   │   ├── comment.js
│   │   │   ├── feedback.js
│   │   │   ├── user.js
│   │   │   ├── group.js
│   │   │   └── notification.js
│   │   ├── routes/
│   │   │   ├── prayerRoutes.js
│   │   │   ├── impressionRoutes.js
│   │   │   ├── commentRoutes.js
│   │   │   ├── feedbackRoutes.js
│   │   │   ├── userRoutes.js
│   │   │   └── groupRoutes.js
│   │   ├── middleware/
│   │   │   ├── auth.js
│   │   │   └── roleCheck.js
│   │   └── services/
│   │       ├── notificationService.js
│   │       └── dashboardService.js
│   ├── package.json
│   └── eslint.config.js
├── firebase.json
└── .firebaserc

## Key Components and Their Responsibilities

1. Controllers:
   - prayerController.js: Handles CRUD operations for prayers, including setting visibility and time frames.
   - impressionController.js: Manages the creation and retrieval of impressions, including count for hidden prayers.
   - commentController.js: Handles the creation and retrieval of comments after the prayer period closes.
   - feedbackController.js: Manages the addition and retrieval of feedback by prayer creators.
   - userController.js: Handles user profile management and dashboard data retrieval.
   - groupController.js: Manages group creation, member addition/removal, and group-related operations.
   - notificationController.js: Handles sending and managing notifications for various app activities.

2. Models:
   - prayer.js: Defines the prayer schema, including fields for visibility, time frame, and impression count.
   - impression.js: Defines the impression schema and related database operations.
   - comment.js: Defines the comment schema and related database operations.
   - feedback.js: Defines the feedback schema and related database operations.
   - user.js: Defines the user schema, including fields for dashboard data and group memberships.
   - group.js: Defines the group schema and group-related database operations.
   - notification.js: Defines the notification schema and related database operations.

3. Routes:
   - prayerRoutes.js: Defines API endpoints for prayer-related operations.
   - impressionRoutes.js: Defines API endpoints for impression-related operations.
   - commentRoutes.js: Defines API endpoints for comment-related operations.
   - feedbackRoutes.js: Defines API endpoints for feedback-related operations.
   - userRoutes.js: Defines API endpoints for user profile and dashboard operations.
   - groupRoutes.js: Defines API endpoints for group-related operations.

4. Middleware:
   - auth.js: Handles authentication for protected routes.
   - roleCheck.js: Verifies user roles for operations requiring specific permissions (e.g., group management, adding feedback).

5. Services:
   - notificationService.js: Handles the logic for sending notifications to users for various app activities.
   - dashboardService.js: Manages the retrieval and organization of data for user dashboards.

This updated structure accommodates the new features and functionalities of the Rhema App, including the separation of impressions and comments, the addition of feedback, and the updated group management system. The new components (like impressionController.js and feedbackController.js) allow for more granular control over these distinct features, while services like dashboardService.js support the new dashboard functionality for user profiles.
