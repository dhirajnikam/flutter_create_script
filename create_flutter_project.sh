#!/bin/bash

# Function to prompt the user for input
prompt_user() {
  read -p "$1: " user_input
  echo $user_input
}

# Prompt the user for the project name and package name
project_name=$(prompt_user "Enter the project name")
package_name=$(prompt_user "Enter the package name (e.g., com.example.project)")

# Create the Flutter project
flutter create --org $package_name $project_name

# Navigate into the project directory
cd $project_name

# Add required packages
flutter pub add fpdart internet_connection_checker_plus flutter_bloc equatable get_it shared_preferences go_router http jwt_decoder bloc_concurrency firebase_core firebase_messaging flutter_local_notifications

# Set up the project structure for clean architecture with feature-first approach
mkdir -p lib/src/{core,features}
mkdir -p lib/src/core/{error,usecases,utils}
mkdir -p lib/src/features/user/{data,domain,presentation}
mkdir -p lib/src/features/user/data/{datasources,models,repositories}
mkdir -p lib/src/features/user/domain/{entities,repositories,usecases}
mkdir -p lib/src/features/user/presentation/{bloc,pages,router}

# Initialize GetIt for Dependency Injection
echo "
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'src/features/user/data/datasources/remote/api_service.dart';
import 'src/features/user/data/repositories/user_repository_impl.dart';
import 'src/features/user/domain/repositories/user_repository.dart';
import 'src/features/user/domain/usecases/get_user.dart';
import 'src/features/user/presentation/bloc/user_bloc.dart';

final sl = GetIt.instance;

void init() {
  sl.registerLazySingleton(() => http.Client());
  
  sl.registerLazySingleton<RemoteDataSource>(
      () => RemoteDataSourceImpl(client: sl()));
  
  sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(remoteDataSource: sl()));
  
  sl.registerLazySingleton(() => GetUser(sl()));
  
  sl.registerFactory(() => UserBloc(getUser: sl()));
}
" > lib/src/injection_container.dart

# Set up the main.dart file with Firebase, Notifications, and GoRouter
echo "
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'src/injection_container.dart' as di;
import 'src/features/user/presentation/router/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  di.init();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  _firebaseMessaging.requestPermission();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService().display(message);
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: '$project_name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
" > lib/main.dart

# Create the NotificationService for handling notifications
echo "
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void initialize() async {
    final InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void display(RemoteMessage message) async {
    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }
}
" > lib/src/core/utils/notification_service.dart

# Create GoRouter setup with deep linking and redirection
echo "
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/user_detail_page.dart';

final List<GoRoute> appRoutes = [
  GoRoute(
    path: '/',
    builder: (context, state) => HomePage(),
    routes: [
      GoRoute(
        path: 'user/:id',
        builder: (context, state) {
          final id = state.params['id']!;
          return UserDetailPage(id: id);
        },
      ),
    ],
  ),
];

final GoRouter router = GoRouter(
  routes: appRoutes,
  redirect: (context, state) {
    final loggedIn = true; // Replace with actual login status check
    final loggingIn = state.subloc == '/login';

    if (!loggedIn && !loggingIn) return '/login';
    if (loggedIn && loggingIn) return '/';

    return null;
  },
  navigatorKey: navigatorKey,
  urlPathStrategy: UrlPathStrategy.path,
);
" > lib/src/features/user/presentation/router/app_router.dart

# Create the Home Page
echo "
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/user_bloc.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read<UserBloc>().add(GetUserEvent(id: '1'));
          },
          child: Text('Get User'),
        ),
      ),
    );
  }
}
" > lib/src/features/user/presentation/pages/home_page.dart

# Create the User Detail Page
echo "
import 'package:flutter/material.dart';

class UserDetailPage extends StatelessWidget {
  final String id;

  UserDetailPage({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Detail'),
      ),
      body: Center(
        child: Text('User ID: \$id'),
      ),
    );
  }
}
" > lib/src/features/user/presentation/pages/user_detail_page.dart

# Initialize Git repository
git init
git add .
git commit -m "Initial commit for $project_name with clean architecture setup, Firebase, notifications, GoRouter, deep linking, and redirection."

# Done
echo "Flutter project '$project_name' has been created with clean architecture, Bloc, Firebase, notifications, GoRouter, deep linking, and redirection."
#!/bin/bash

# Function to prompt the user for input
prompt_user() {
  read -p "$1: " user_input
  echo $user_input
}

# Prompt the user for the project name and package name
project_name=$(prompt_user "Enter the project name")
package_name=$(prompt_user "Enter the package name (e.g., com.example.project)")

# Create the Flutter project
flutter create --org $package_name $project_name

# Navigate into the project directory
cd $project_name

# Add required packages
flutter pub add fpdart internet_connection_checker_plus flutter_bloc equatable get_it shared_preferences go_router http jwt_decoder bloc_concurrency

# Set up the project structure for clean architecture
mkdir -p lib/src/{data,domain,presentation}
mkdir -p lib/src/data/{datasources,models,repositories}
mkdir -p lib/src/domain/{entities,repositories,usecases}
mkdir -p lib/src/presentation/{bloc,widgets,views}

# Initialize GetIt for Dependency Injection
echo "
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void init() {
  // Register all dependencies here
}
" > lib/src/injection_container.dart

# Set up the main.dart file
echo "
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'src/injection_container.dart' as di;

void main() {
  di.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$project_name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('$project_name'),
        ),
        body: Center(
          child: Text('Hello World'),
        ),
      ),
    );
  }
}
" > lib/main.dart

# Initialize Git repository
git init
git add .
git commit -m "Initial commit for $project_name with clean architecture setup and required packages"

# Done
echo "Flutter project '$project_name' has been created with clean architecture and Bloc using the provided packages."