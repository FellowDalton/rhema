# Rhema App Frontend Development Prompts

Use these prompts to guide the development of the Rhema App frontend. Ensure that all Vue components use script setup, BEM style notation for CSS classes, CSS grid for layouts where appropriate, and prefer clamp() over media queries for responsive design. Maintain consistency across components and ensure proper integration with Firebase services.

## Core Setup

1. "Please write the code for src/main.js, setting up our Vue 3 app with Vue Router, Vuex, and Firebase integration."

2. "Create src/App.vue as the main component. Use script setup and include a basic layout with router-view."

3. "Implement src/router/index.js with Vue Router configuration, including routes for Dashboard, Prayer, Login, Register, and Group views. Include navigation guards for authenticated routes."

4. "Set up src/store/index.js with Vuex, importing and combining all module stores (prayer, group, user, impression, comment, feedback, notifications, auth, firebase)."

## Firebase Setup

5. "Create src/config/firebase.js to initialize Firebase with our app's configuration."

6. "Implement src/plugins/firebase.js as a Vue plugin to integrate Firebase into our app."

7. "Develop src/services/firebase.js with methods for Firebase operations (CRUD for prayers, groups, etc., and authentication methods)."

8. "Write src/composables/useFirebase.js as a composable for reusable Firebase logic across components."

## Atom Components

9. "Implement src/components/atoms/RhButton.vue as a reusable button component with primary and secondary variants. Use BEM for styling."

10. "Create src/components/atoms/RhInput.vue as a reusable input component. Include validation states and error display."

11. "Develop src/components/atoms/RhTextarea.vue as a reusable textarea component with auto-resize functionality."

12. "Implement src/components/atoms/RhIcon.vue for displaying SVG icons. Include a set of common icons used in the app."

13. "Create src/components/atoms/RhAvatar.vue for user avatars. Include options for image or initials display."

14. "Develop src/components/atoms/RhLoader.vue as a loading spinner component with size variants."

## Molecule Components

15. "Implement src/components/molecules/RhFormGroup.vue, combining RhInput or RhTextarea with a label and error message."

16. "Create src/components/molecules/RhCard.vue as a base card component with slots for header, content, and footer."

17. "Develop src/components/molecules/RhModal.vue as a reusable modal component with slots for header, content, and footer."

18. "Implement src/components/molecules/RhTag.vue for displaying user and group tags. Include a remove option."

19. "Create src/components/molecules/RhCommentItem.vue for individual comment display. Include options for editing and replying."

20. "Develop src/components/molecules/RhImpressionInput.vue for adding new impressions. Integrate with Firebase for real-time updates."

21. "Implement src/components/molecules/RhSearchBar.vue with debounced input and clear functionality."

## Organism Components

22. "Create src/components/organisms/RhHeader.vue with logo, navigation links, and user profile menu. Use RhAvatar for the user profile."

23. "Implement src/components/organisms/RhPrayerCard.vue to display prayer details. Include RhTags for participants and use RhButton for actions."

24. "Develop src/components/organisms/RhPrayerList.vue to display a list of RhPrayerCard components. Implement infinite scrolling."

25. "Create src/components/organisms/RhCommentSection.vue with nested comments and replies. Use RhCommentItem for individual comments."

26. "Implement src/components/organisms/RhImpressionList.vue to display impressions. Include RhImpressionInput for adding new impressions."

27. "Develop src/components/organisms/RhFilterBar.vue with filter options for prayers and groups. Use RhButton for filter toggles."

28. "Create src/components/organisms/RhFeedbackSection.vue for displaying and adding feedback to prayers."

29. "Implement src/components/organisms/RhNotificationCenter.vue to display user notifications. Integrate with Firebase for real-time updates."

30. "Develop src/components/organisms/RhGroupList.vue and RhGroupCard.vue for displaying groups. Use RhCard as a base."

## Template Components

31. "Create src/components/templates/RhDashboardTemplate.vue as a layout for the dashboard. Include RhHeader, RhFilterBar, and slots for main content."

32. "Implement src/components/templates/RhPrayerPageTemplate.vue as a layout for individual prayer pages. Include sections for prayer details, impressions, comments, and feedback."

33. "Develop src/components/templates/RhModalTemplate.vue as a base template for all modals in the app."

34. "Create src/components/templates/RhAuthTemplate.vue as a layout for login and registration pages."

## Views

35. "Implement src/views/DashboardView.vue using RhDashboardTemplate. Include RhPrayerList and RhGroupList."

36. "Create src/views/PrayerView.vue using RhPrayerPageTemplate. Integrate all prayer-related components."

37. "Develop src/views/LoginView.vue and RegisterView.vue using RhAuthTemplate. Implement login and registration forms."

38. "Implement src/views/GroupView.vue for displaying group details and prayers within a group."

## Modals

39. "Create src/modals/CreatePrayerModal.vue using RhModalTemplate. Implement a form for creating new prayers."

40. "Implement src/modals/CreateGroupModal.vue using RhModalTemplate. Include a form for creating new groups."

41. "Develop src/modals/SendPrayerModal.vue for sending prayer content. Include options for copying to clipboard."

42. "Create src/modals/AddFeedbackModal.vue for adding feedback to prayers."

## Composables

43. "Implement src/composables/usePrayer.js with logic for managing prayers (CRUD operations, filtering, etc.)."

44. "Create src/composables/useGroup.js for group management functionality."

45. "Develop src/composables/useImpression.js and useComment.js for handling impressions and comments."

46. "Implement src/composables/useFeedback.js for managing prayer feedback."

47. "Create src/composables/useNotifications.js for handling user notifications."

48. "Develop src/composables/useAuth.js for authentication logic, working with useFirebase."

49. "Implement src/composables/useSearch.js for search functionality across prayers and groups."

50. "Create src/composables/useDashboard.js for fetching and managing dashboard data."

## Store Modules

51. "Implement Vuex store modules for each feature (prayer.js, group.js, user.js, impression.js, comment.js, feedback.js, notifications.js, auth.js, firebase.js) in the src/store directory. Ensure integration with Firebase services."

## Utilities and Services

52. "Create src/utils/helpers.js with general utility functions used across the app."

53. "Implement src/utils/dateUtils.js for date formatting and manipulation functions."

54. "Develop src/utils/firebaseUtils.js with Firebase-specific utility functions."

55. "Create src/services/api.js as a centralized service for API calls, integrating with Firebase services."

## Styles and Constants

56. "Implement src/assets/styles/variables.css with CSS variables for colors, typography, spacing, etc."

57. "Create src/assets/styles/global.css with global styles and utility classes."

58. "Develop src/constants/index.js with app-wide constant values."

Remember to maintain consistency across components, ensure proper integration with Firebase services, and follow Vue 3 best practices throughout the development process.
