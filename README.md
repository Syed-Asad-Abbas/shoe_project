# Shoe E-Commerce System Documentation

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Backend](#backend)
   - [Technologies](#backend-technologies)
   - [API Endpoints](#api-endpoints)
   - [Database Schema](#database-schema)
   - [Authentication](#authentication)
4. [Client Application](#client-application)
   - [Technologies](#client-technologies)
   - [Screens & Features](#client-screens--features)
   - [State Management](#client-state-management)
5. [Admin Panel](#admin-panel)
   - [Technologies](#admin-technologies)
   - [Screens & Features](#admin-screens--features)
   - [State Management](#admin-state-management)
6. [Data Flow](#data-flow)
7. [Deployment](#deployment)
8. [Troubleshooting](#troubleshooting)
9. [Future Enhancements](#future-enhancements)

## System Overview

The Shoe E-Commerce System is a full-stack application consisting of three main components:

1. **Backend API**: A RESTful API built with Express.js and MongoDB that handles data storage, business logic, and authentication.
2. **Client Application**: A Flutter-based mobile application for customers to browse products, make purchases, and manage their accounts.
3. **Admin Panel**: A separate Flutter application for store administrators to manage products, orders, customers, and view analytics.

This system follows a client-server architecture where the backend serves as the central hub for data management, while the client and admin applications consume this data through API calls.

## Architecture

The system follows a three-tier architecture:

1. **Presentation Layer**:
   - Client App (Flutter)
   - Admin Panel (Flutter)

2. **Business Logic Layer**:
   - Express.js Backend
   - API Controllers
   - Authentication Middleware

3. **Data Layer**:
   - MongoDB Database
   - Mongoose Models

![Architecture Diagram](https://example.com/architecture.png)

The system employs a RESTful API design pattern, with JSON as the data exchange format between the server and clients. Authentication is handled via JWT (JSON Web Tokens) to secure API endpoints.

## Backend

### Backend Technologies

- **Node.js**: Runtime environment
- **Express.js**: Web framework
- **MongoDB**: NoSQL database
- **Mongoose**: ODM (Object Data Modeling) for MongoDB
- **JSON Web Token (JWT)**: For authentication
- **Cors**: For handling Cross-Origin Resource Sharing
- **Body-parser**: For parsing request bodies

### API Endpoints

#### Authentication

- `POST /api/v1/auth/login`: Authenticate user/admin and get JWT token

#### Products

- `GET /api/v1/products`: Get all products
- `GET /api/v1/products/:id`: Get product by ID
- `GET /api/v1/products/search?q=:query`: Search products
- `GET /api/v1/products/featured`: Get featured products
- `GET /api/v1/products?category=:category`: Get products by category

#### Admin Products

- `GET /api/v1/admin/products`: Get all products (admin)
- `GET /api/v1/admin/products/:id`: Get product by ID (admin)
- `POST /api/v1/admin/products`: Create new product
- `PUT /api/v1/admin/products/:id`: Update product
- `DELETE /api/v1/admin/products/:id`: Delete product

#### Orders

- `GET /api/v1/admin/orders`: Get all orders (admin)
- `GET /api/v1/admin/orders/:id`: Get order by ID (admin)
- `PATCH /api/v1/admin/orders/:id/status`: Update order status

#### Customers

- `GET /api/v1/admin/customers`: Get all customers (admin)
- `GET /api/v1/admin/customers/:id`: Get customer by ID (admin)

#### Analytics

- `GET /api/v1/admin/analytics/sales-overview`: Get sales overview data
- `GET /api/v1/admin/analytics/sales?period=:period`: Get sales data by period
- `GET /api/v1/admin/analytics/top-products`: Get top selling products
- `GET /api/v1/admin/analytics/customer-acquisition`: Get customer acquisition data
- `GET /api/v1/admin/analytics/order-status`: Get order status distribution
- `GET /api/v1/admin/analytics/low-inventory`: Get products with low inventory

### Database Schema

#### Product Model

```javascript
{
  id: String,
  name: String,
  description: String,
  price: Number,
  imageUrl: String,
  category: String,
  sizes: [Number],
  colors: [String],
  inStock: Boolean,
  discount: Number,
  rating: Number,
  reviewCount: Number,
  stockQuantity: Number,
  featured: Boolean
}
```

#### Order Model

```javascript
{
  id: String,
  customerId: String,
  customerName: String,
  email: String,
  phone: String,
  items: [
    {
      productId: String,
      name: String,
      quantity: Number,
      price: Number,
      size: Number,
      color: String
    }
  ],
  totalAmount: Number,
  status: Number, // 0: Pending, 1: Processing, 2: Shipped, 3: Delivered, 4: Cancelled, 5: Refunded
  date: Date,
  shippingAddress: String,
  paymentMethod: String
}
```

#### User Model

```javascript
{
  id: String,
  name: String,
  email: String,
  password: String, // Hashed
  phone: String,
  address: String,
  role: String, // 'customer' or 'admin'
  createdAt: Date,
  orderCount: Number
}
```

### Authentication

The backend uses JWT (JSON Web Token) for authentication:

1. Users/Admins authenticate by sending credentials to `/api/v1/auth/login`
2. The server validates credentials and issues a JWT token
3. Subsequent API requests include this token in the `x-auth-token` header
4. Protected routes use the `authenticate` middleware to verify tokens

JWT tokens contain the user's ID, email, and role, and expire after 7 days.

## Client Application

### Client Technologies

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **http**: HTTP client for API requests
- **shared_preferences**: Local storage
- **flutter_secure_storage**: Secure storage for sensitive data

### Client Screens & Features

1. **Splash Screen**:
   - App loading and initialization
   - Check authentication status

2. **Authentication**:
   - Login
   - Registration
   - Password recovery

3. **Home Screen**:
   - Featured products carousel
   - Categories
   - New arrivals
   - Promotions

4. **Product Listing**:
   - Grid view of products
   - Filtering and sorting
   - Search functionality

5. **Product Details**:
   - Image gallery
   - Product information
   - Size and color selection
   - Add to cart
   - Add to favorites

6. **Cart**:
   - View cart items
   - Update quantities
   - Remove items
   - Apply coupon codes
   - Checkout

7. **Checkout**:
   - Shipping information
   - Payment methods
   - Order summary
   - Order confirmation

8. **User Profile**:
   - Personal information
   - Order history
   - Shipping addresses
   - Payment methods
   - Favorites

### Client State Management

The client app uses Provider for state management with the following key providers:

1. **AuthProvider**: Handles user authentication, registration, and profile management
2. **ProductProvider**: Manages product data, categories, and search functionality
3. **CartProvider**: Handles shopping cart operations
4. **OrderProvider**: Manages order creation and history

## Admin Panel

### Admin Technologies

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **http**: HTTP client for API requests
- **flutter_secure_storage**: Secure storage for sensitive data
- **fl_chart**: Chart visualization
- **data_table_2**: Enhanced data tables
- **flutter_admin_scaffold**: Admin panel UI framework

### Admin Screens & Features

1. **Login Screen**:
   - Admin authentication
   - Secure token storage

2. **Dashboard**:
   - Sales overview
   - Revenue metrics
   - Recent orders
   - Low inventory alerts
   - Customer acquisition chart

3. **Products Management**:
   - Product listing with search and filters
   - Add new products
   - Edit existing products
   - Delete products
   - Manage inventory

4. **Orders Management**:
   - Order listing with search and filters
   - Order details
   - Update order status
   - Order history

5. **Customer Management**:
   - Customer listing with search
   - Customer details
   - Order history by customer

6. **Analytics**:
   - Sales trends (daily, weekly, monthly)
   - Top-selling products
   - Customer acquisition
   - Order status distribution

7. **Settings**:
   - Admin account management
   - Store settings
   - Notification preferences

### Admin State Management

The admin panel uses Provider for state management with the following key providers:

1. **AuthProvider**: Handles admin authentication and session management
2. **ProductProvider**: Manages product data and CRUD operations
3. **OrderProvider**: Handles order data and status updates
4. **CustomerProvider**: Manages customer data
5. **AnalyticsProvider**: Handles analytics data fetching and processing

## Data Flow

The data flow in the system follows this pattern:

1. **Client to Backend**:
   - Client app makes API requests to the backend
   - Data is validated and processed by the backend
   - Responses are sent back to the client

2. **Admin to Backend**:
   - Admin panel makes API requests to the backend
   - Admin-specific endpoints require admin authentication
   - Backend returns admin-specific data

3. **Backend to Database**:
   - Backend queries MongoDB for data
   - Mongoose models handle data validation and formatting
   - Database operations are performed as needed

4. **Real-time Updates**:
   - Currently, the system uses polling for updates
   - Future enhancements may include WebSocket implementation for real-time updates

## Deployment

### Backend Deployment

1. **Prerequisites**:
   - Node.js runtime
   - MongoDB database
   - Environment variables for configuration

2. **Steps**:
   - Clone repository
   - Install dependencies: `npm install`
   - Configure environment variables
   - Start server: `npm start`

### Client App Deployment

1. **Prerequisites**:
   - Flutter SDK
   - Android Studio / Xcode

2. **Steps**:
   - Clone repository
   - Install dependencies: `flutter pub get`
   - Configure API endpoints
   - Build for target platform:
     - Android: `flutter build apk`
     - iOS: `flutter build ios`

### Admin Panel Deployment

1. **Prerequisites**:
   - Flutter SDK
   - Android Studio / Xcode

2. **Steps**:
   - Clone repository
   - Install dependencies: `flutter pub get`
   - Configure API endpoints
   - Build for target platform:
     - Android: `flutter build apk`
     - iOS: `flutter build ios`
     - Web: `flutter build web`

## Troubleshooting

### Common Issues and Solutions

1. **API Connection Issues**:
   - Check API endpoint configuration
   - Verify network connectivity
   - Check authentication tokens

2. **Authentication Problems**:
   - Clear stored tokens
   - Re-authenticate
   - Check token expiration

3. **Data Loading Issues**:
   - Check API responses for errors
   - Verify data models match API response format
   - Implement proper error handling

4. **UI Rendering Issues**:
   - Check device compatibility
   - Verify responsive design implementation
   - Test on multiple screen sizes

### Logging

- Backend uses console logging for errors and important events
- Client and admin applications use Flutter's logging system
- Consider implementing a centralized logging system for production environments

## Future Enhancements

1. **Real-time Updates**:
   - Implement WebSockets for instant order updates
   - Real-time inventory management
   - Live chat support

2. **Advanced Analytics**:
   - Enhanced reporting features
   - Predictive analytics for inventory management
   - Customer behavior analysis

3. **Payment Integration**:
   - Multiple payment gateways
   - Subscription-based products
   - Installment payment options

4. **Enhanced User Experience**:
   - AR try-on feature for shoes
   - Size recommendation engine
   - Personalized product recommendations

5. **Performance Optimization**:
   - Caching strategies
   - Image optimization
   - Database indexing for faster queries 
