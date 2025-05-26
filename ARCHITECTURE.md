<!--- This file contains the architecture planned for each stage of the project. -->
# Comprehensive Prompt for Comnecter - Advanced Location-Based Social Networking App

Create a sophisticated mobile application with the following specifications:

## App Name and Purpose
Build "Comnecter" - an advanced location-based social networking application designed to help users discover and connect with nearby people who share similar interests. The app emphasizes real-world connections by using radar visualization to detect nearby users, enabling direct messaging after establishing connections, supporting community creation around shared interests, and offering unique insights into friendship dynamics.

## Core Visual Design
- **Color Scheme**: Use a modern, vibrant palette with primary color #3E64FF (bright blue), secondary color #5EDFFF (light blue), and accent color #FFC857 (yellow)
- **Design Language**: Implement a clean, modern UI with subtle animations throughout the interface
- **Animations**: Create smooth transitions between screens, subtle micro-interactions, and a captivating radar animation for the main feature
- **Dark/Light Modes**: Support both with appropriate color adaptations
- **Layout**: Employ rounded corners (12-16px radius), comfortable padding, and clear visual hierarchy
- **Typography**: Use Poppins font family with appropriate weight variations for different UI elements
- **Iconography**: Utilize Material Icons consistently across the app

## Main Components & Features

### 1. Navigation Structure
- Implement a tab-based navigation with 5 main sections:
  - Radar (Nearby Users)
  - Chats
  - Communities
  - Profile
  - Events
- Include settings access from all main screens
- Design smooth transitions between tabs

### 2. Radar Screen
- Create an animated radar visualization that "scans" for nearby users
- Display nearby users as dots on the radar with distance-appropriate positioning
- Show pulsating animation for newly detected users
- Include distance rings with kilometer markings
- Implement a pull-to-refresh mechanism to update nearby users
- Add a slider to adjust maximum detection range (1-20km)
- Display a list of nearby users below the radar with:
  - Profile picture/initial
  - Name
  - Distance
  - Common interests
  - Action buttons based on connection status
- Create detailed user profile modals when tapping on users
- Implement sound effects for radar scanning and user detection

### 3. Chat Functionality
- Display active conversations with:
  - Profile pictures with online status indicators
  - Usernames
  - Last message preview
  - Timestamp
  - Unread message count
- Implement detailed chat view with:
  - Message bubbles (different colors for sent/received)
  - Timestamps
  - Read receipts
  - Text input with send button
  - Smooth animations for new messages
  - Ability to switch between direct and community chats
- Add video and voice call capabilities

### 4. Communities Section
- Design tabs for "Discover" and "My Communities"
- Display community cards with:
  - Cover image or gradient
  - Name
  - Tag (with @ prefix)
  - Brief description
  - Member count
  - Join/View buttons
- Create community creation flow with:
  - Name and unique tag input
  - Description
  - Interest tag selection
  - Privacy settings
- Implement member management features
- Add community chat functionality

### 5. User Profiles
- Create customizable profiles with:
  - Profile picture/animation options
  - Username and display name
  - Editable bio
  - Interest tags
  - Background customization options
- Show profile statistics (friends, communities, posts)
- Implement Friends Insight feature for transparency in social interactions
- Add privacy controls for profile visibility

### 6. Events
- Design event creation and management system
- Implement event discovery based on location and interests
- Allow users to create, join, and RSVP to events
- Display event details including:
  - Title, description, date/time
  - Location (with map integration)
  - Attendee list
  - Event chat

### 7. Friends Insight Feature
- Implement a unique feature that provides insights into friendship dynamics
- Track and display (with user consent):
  - Friend requests accepted/declined
  - When users are blocked/unblocked
  - Friend removals
  - Message seen but not replied status
  - Group chat removals
- Create a dedicated screen to view friendship activity history
- Implement privacy settings to control Friends Insight visibility

### 8. Onboarding Flow
- Create visually appealing intro screens
- Design profile creation with:
  - Name and username inputs
  - Interest selection
  - Location permission request
  - Animated transitions between steps
- Implement validation for usernames

### 9. Settings Screen
- Add toggles for:
  - Dark/light mode
  - Notifications
  - Location services
  - Radar visibility
  - Maximum search distance
  - Friends Insight options
- Include account management options
- Add about section with app info

### 10. Notifications System
- Implement push notifications for:
  - New messages
  - Friend requests
  - Nearby user alerts
  - Community invitations and updates
  - Event reminders
- Create an in-app notification center

## Technical Requirements

### Data Models
- User model with profile info, location data, online status, friends lists
- Chat and message models for conversation management
- Community model for group organization
- Event model for event management
- Notification model for system alerts
- FriendshipChange model for Friends Insight feature

### State Management
- Use Provider pattern for app-wide state
- Implement local data persistence using shared_preferences
- Create simulated backend services for all features
- Include proper error handling throughout the app

### Service Layer
- Design services for:
  - User management
  - Chat functionality
  - Community features
  - Event management
  - Notifications
  - Location/radar features
  - Friends Insight tracking
  - Sound effects

### UI Components
- Develop reusable widgets for:
  - User avatars with customization options
  - Enhanced radar visualization
  - Message bubbles with status indicators
  - Community and event cards
  - Notification badges
  - Profile sections with animations
  - Friends Insight activity cards

### Animations & Effects
- Implement subtle animations for:
  - Tab transitions
  - List item appearances
  - Button interactions
  - Radar scanning effect
  - Profile elements
  - Friends Insight activity displays
- Add sound effects for key interactions

### Location Services
- Implement geolocation services for user positioning
- Create distance calculation functions
- Implement privacy controls for location sharing

### Security & Privacy
- Implement user authentication (simulated)
- Add data encryption for sensitive information
- Create privacy settings for user discoverability and data sharing

## Implementation Notes
- Focus on a clean, maintainable architecture
- Include realistic sample data for all features
- Create fallback mechanisms for location services
- Implement proper error handling and loading states
- Optimize the radar feature for smooth performance
- Add appropriate platform permissions for location features
- Ensure accessibility with proper contrast and text sizes
- Include shimmer loading effects and placeholders
- Implement caching mechanisms for better offline experience

Develop this complete application with production-ready architecture, beautiful design, and functional features that demonstrate real-world social networking capabilities. The app should provide a seamless experience for discovering and connecting with nearby users, joining communities, organizing events, and gaining insights into social interactions.