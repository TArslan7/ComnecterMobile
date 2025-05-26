# Comnecter - Social Networking App Documentation

## Overview

Comnecter is a sophisticated location-based social networking application designed to help users discover and connect with nearby people who share similar interests. Unlike traditional social media platforms that focus primarily on virtual interactions, Comnecter emphasizes creating real-world connections by leveraging geolocation technology to identify nearby users and facilitate face-to-face meetings.

The name "Comnecter" is a blend of "community" and "connect," reflecting the app's dual focus on individual connections and community building.

## Core Purpose

The primary purposes of Comnecter are:

1. **Proximity-Based Discovery**: Help users find like-minded people who are physically nearby
2. **Real-World Connection Facilitation**: Bridge the gap between online and offline social interactions
3. **Community Building**: Enable users to form and join communities based on shared interests
4. **Transparent Social Interactions**: Provide insights into friendship dynamics through the unique Friends Insight feature

## Key Features

### 1. Radar & Nearby User Discovery

The centerpiece of Comnecter is its innovative radar visualization system that helps users discover others nearby:

- **Animated Radar Interface**: A visually appealing radar display that "scans" for nearby users and represents them as dots positioned according to their relative distance and direction
- **Distance Rings**: Concentric circles on the radar showing distance markers in kilometers
- **User Dots**: Interactive dots representing nearby users with pulsating animations for newly detected users
- **Sound Effects**: Optional auditory feedback with different sounds for detection events
- **Distance Filtering**: Adjustable maximum detection range (slider controls) to focus on users within a specific radius
- **User List View**: Detailed list of nearby users showing:
  - Profile pictures/avatars
  - Names and usernames
  - Approximate distance
  - Shared interests
  - Action buttons (send friend request, start chat)
- **Profile Preview**: Quick-access detailed user profiles with interaction options
- **Search & Filter**: Tools to find specific users or filter by distance, interests, or other criteria

### 2. Sophisticated Chat System

A comprehensive messaging system for both direct and community-based communication:

- **Direct Messaging**: One-on-one conversations between users with:
  - Real-time message delivery
  - Read status indicators
  - Message timestamps
  - Animated message bubbles
  - Different colored bubbles for sent vs. received messages
- **Community Chat**: Group conversations within communities
- **Chat List**: Organized inbox showing:
  - Active conversations
  - Online status indicators
  - Message previews
  - Unread message counts
  - Timestamp of last activity
- **Tabbed Interface**: Separate tabs for direct chats and community chats
- **Voice and Video Calling**: Ability to initiate voice or video calls from chat screens
- **Interactive Elements**: Typing indicators and smooth animations

### 3. Community Features

Extensive community functionality allowing users to create and join interest-based groups:

- **Community Discovery**: Browse and search available communities with filtering options
- **Community Creation**: Create new communities with:
  - Custom name and unique tag (with @ prefix)
  - Descriptive information
  - Interest tags for categorization
  - Privacy settings (public/private)
  - Member limits
  - Requirements for joining
- **Community Management**: Tools for:
  - Member administration
  - Content moderation
  - Activity tracking
  - Community chat management
- **Visual Representation**: Attractive community cards showing:
  - Cover images/gradient backgrounds
  - Community name and tag
  - Brief description
  - Member count
  - Primary interest tags
- **Membership Management**: Join, leave, or request to join communities with appropriate notifications

### 4. User Profiles & Customization

Detailed and customizable user profiles that showcase personality and interests:

- **Profile Information**: Comprehensive user data including:
  - Display name and unique username
  - Profile picture/avatar with customization options
  - Bio/about section
  - Interest tags
  - Friendship status
  - Activity statistics
- **Visual Customization**: Options to customize:
  - Profile background (images or animated gradients)
  - Color schemes
  - Visual effects and animations
- **Profile Content**: Ability to share posts, photos, or other content on profiles
- **Profile Statistics**: Visual representation of user activity statistics including:
  - Friend count
  - Community memberships
  - Activity metrics
  - Animated visualizations of stats

### 5. Friends Insight Feature

A unique transparency tool that provides visibility into friendship dynamics:

- **Friendship Change Tracking**: Record and display (with user consent):
  - Friend requests accepted/declined
  - When users are blocked/unblocked
  - Friend removals
  - Message seen but not replied status
  - Group chat removals
- **Privacy Controls**: Granular settings to determine who can see which types of insight information
- **Chronological View**: Timeline of friendship-related activities
- **Mutual Visibility**: Certain sensitive insights are only visible when both users have enabled Friends Insight
- **Activity Cards**: Visual representation of friendship changes with appropriate context

### 6. Events System (Coming Soon/Partial Implementation)

Tools for organizing and managing in-person gatherings:

- **Event Creation**: Create events with:
  - Title and description
  - Date and time information
  - Location details with map integration
  - Tags and categories
  - Cover images
  - Participant limits
- **Event Discovery**: Find events based on:
  - Location proximity
  - Interest relevance
  - Date/time
  - Community association
- **RSVP Functionality**: Ability to indicate attendance status
- **Event Management**: Tools for organizers to:
  - Track attendees
  - Send updates
  - Manage event details
  - Communicate with participants

### 7. Settings & Customization

Extensive user-controlled configuration options:

- **App Settings**:
  - Dark/light mode toggle
  - Notification preferences
  - Sound effect options
  - Location services configuration
  - Maximum search distance adjustment
  - Friends Insight controls
  - Privacy settings
- **Account Management**:
  - Profile editing
  - Username changes (with uniqueness validation)
  - Password management
  - Account privacy controls
  - Data management options
- **Radar Settings**:
  - Visibility controls (be visible/invisible on others' radars)
  - Maximum detection range
  - Sound effect toggles

### 8. Notifications System

Comprehensive notifications for important app events:

- **Notification Types**:
  - Chat messages
  - Friend requests
  - Friend request acceptances
  - Nearby user alerts
  - Community invitations and updates
  - Event reminders
  - System announcements
- **In-App Notification Center**: Organized view of all notifications with:
  - Categorized tabs (messages, friends, nearby, communities, system)
  - Read/unread status
  - Timestamp information
  - Quick action buttons
- **Interactive Notifications**: Ability to take actions directly from notifications

## User Experience & Flow

### Onboarding Process

A streamlined, engaging introduction to the app:

1. **Welcome Screens**: Introduction to app concept and key features with animations
2. **Profile Creation**:
   - Name and username input (with uniqueness validation)
   - Interest selection from predefined categories
   - Option to add custom interests
   - Visual feedback and animations during the process
3. **Location Permissions**: Request for location access with clear explanation of usage
4. **Home Screen Introduction**: Brief tutorial on main app sections and features

### Main Navigation Structure

Intuitive navigation through five primary sections:

1. **Radar Screen**: Primary discovery interface showing the radar visualization and nearby users
2. **Chats**: Messaging hub with tabs for direct messages and community conversations
3. **Communities**: Section for browsing, creating, and managing community memberships
4. **Profile**: User's own profile with customization options and activity statistics
5. **Events**: Interface for event discovery and management (partially implemented/coming soon)

### Interactions & Transitions

- **Smooth Animations**: Subtle transitions between screens and interface elements
- **Sound Feedback**: Optional auditory cues for important actions and events
- **Micro-interactions**: Small animated responses to user actions throughout the app
- **Loading States**: Visually appealing loading indicators and placeholder content

## Technical Architecture

### Data Models

The app is built around several key data models:

1. **UserModel**: Represents app users with properties for:
   - User identity (ID, name, username)
   - Profile information (avatar, bio, interests)
   - Location data (latitude, longitude)
   - Relationship data (friends, blocked users, friend requests)
   - Settings and preferences

2. **ChatModel & MessageModel**: Handle messaging functionality:
   - ChatModel: Represents conversation containers between users or in communities
   - MessageModel: Individual messages with sender, content, timestamp, and status information

3. **CommunityModel**: Represents interest-based groups with:
   - Identity information (name, tag, description)
   - Membership data (members, pending members, owner)
   - Configuration (privacy settings, member limits, requirements)

4. **EventModel**: Manages event data with:
   - Event details (title, description, dates, location)
   - Participant information
   - Organization data (organizers, co-organizers)
   - Status tracking (draft, published, cancelled, completed)

5. **AppNotification**: Handles in-app notifications with:
   - Content (title, body, associated data)
   - Type classification
   - Status tracking (read/unread)

6. **FriendshipChange**: Tracks friendship dynamics for the Friends Insight feature

### State Management

The app uses Provider pattern for state management with several key providers:

1. **UserProvider**: Manages current user data and nearby user discovery
2. **ChatProvider**: Handles chat conversations and messaging
3. **CommunityProvider**: Manages community data and interactions
4. **NotificationService**: Provides notification functionality
5. **EventProvider**: Handles event creation and management

### Services Layer

Service classes handle specific functionality domains:

1. **UserService**: Manages user data operations
2. **ChatService**: Handles messaging functionality
3. **CommunityService**: Provides community-related operations
4. **NotificationService**: Manages the notification system
5. **SoundService**: Handles sound effects throughout the app
6. **LocationService**: Manages geolocation functionality
7. **FriendshipInsightService**: Tracks and provides friendship dynamics data

### Storage Strategy

The app supports two storage modes:

1. **Local Storage**: Uses SharedPreferences for data persistence on the device
2. **Firebase Integration**: Optional connection to Firebase for cloud storage and real-time features (requires setup)

## Visual Design Elements

### Color Scheme

- **Primary Color**: #3E64FF (bright blue) - Used for primary actions, key UI elements
- **Secondary Color**: #5EDFFF (light blue) - Used for secondary elements, accents
- **Accent Color**: #FFC857 (yellow) - Used for highlights, call-to-action elements
- **Light Mode Colors**:
  - Background: #F5F7FB (light gray-blue)
  - Card: #FFFFFF (white)
  - Text: #333333 (dark gray)
- **Dark Mode Colors**:
  - Background: #121212 (very dark gray)
  - Card: #1E1E1E (dark gray)
  - Text: #F5F5F5 (off-white)

### Typography

- **Font Family**: Poppins (Google Font)
- **Text Hierarchy**:
  - Large titles: 22px, 600 weight
  - Medium titles: 18px, 600 weight
  - Small titles: 16px, 500 weight
  - Body text: 14-16px, 400 weight
  - Small text: 12px, 400 weight
- **Button Text**: 16px, 600 weight

### Interface Elements

- **Cards**: Rounded corners (16px radius), subtle elevation, clean layouts
- **Buttons**: Three primary styles:
  - Primary: Filled with primary color, white text
  - Secondary: Outlined with primary color border
  - Tertiary: Text-only with primary color
- **Input Fields**: Rounded corners, filled background, animated focus states
- **Chips**: Used for interests and filters, with selection states
- **Icons**: Clean, modern line icons with consistent sizing

### Specialized UI Components

- **Radar Visualization**: Custom-drawn radar with:
  - Concentric distance rings
  - Animated sweep line
  - User dot representation
  - Grid overlay
- **Chat Bubbles**: Stylized message containers with:
  - Different styles for sent vs. received messages
  - Status indicators (sent, delivered, read)
  - Timestamp information
- **Profile Stats Animation**: Animated displays of user statistics
- **Confetti Effect**: Celebratory animation for achievements

## Security & Privacy

### User Data Protection

- **Location Privacy**: Controls for visibility on radar
- **Message Privacy**: Private conversations with appropriate access controls
- **Profile Visibility**: Settings to control who can view profile information

### Friend & Block Functionality

- **Friend Requests**: System for establishing connections between users
- **Blocking**: Ability to block unwanted interactions from specific users
- **Friend Management**: Tools to view, organize, and manage connections

### Community Privacy

- **Private Communities**: Option to create invite-only or approval-required communities
- **Moderation Tools**: Features for community owners to manage membership

## Implementation Notes

### Performance Optimizations

- **Efficient Rendering**: Optimized UI components for smooth performance
- **Background Processing**: Handling intensive tasks off the main thread
- **Caching Mechanisms**: Local storage of frequently accessed data

### Fallback Mechanisms

- **Offline Mode**: Basic functionality when network is unavailable
- **Location Unavailable**: Alternative experience when location services are disabled
- **Firebase Optional**: Ability to run with local storage when Firebase is not configured

### Future Enhancements (Planned)

- **Full Event System**: Complete implementation of the event creation and management functionality
- **Enhanced Media Sharing**: Expanded options for sharing photos, videos, and other media
- **Advanced Friend Suggestions**: AI-powered recommendations based on interests and activity
- **Group Video Calls**: Multi-user video conferencing within communities
- **Location-Based Content**: Discover content relevant to specific geographic areas

## Conclusion

Comnecter represents a new approach to social networking that prioritizes meaningful, physical-world connections facilitated by technology. By combining location awareness, interest-based matching, transparent social dynamics, and community building, the app creates opportunities for users to expand their social circles in authentic ways.

With its beautiful interface, intuitive navigation, and rich feature set, Comnecter offers a sophisticated platform for discovering and connecting with like-minded individuals in your vicinity, potentially transforming how people build new relationships in an increasingly digital world.