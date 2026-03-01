import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/patient_selection/presentation/pages/my_patients_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/health/presentation/pages/health_overview_page.dart';
import '../../features/health/presentation/pages/health_metric_detail_page.dart';
import '../../features/health/presentation/pages/new_health_record_page.dart';
import '../../features/health/presentation/pages/health_plan_config_page.dart';
import '../../features/medications/presentation/pages/medications_today_page.dart';
import '../../features/medications/presentation/pages/medication_detail_page.dart';
import '../../features/medications/presentation/pages/create_edit_med_plan_page.dart';
import '../../features/medications/presentation/pages/medication_search_page.dart';
import '../../features/medications/presentation/pages/dose_history_page.dart';
import '../../features/activities/presentation/pages/activities_feed_page.dart';
import '../../features/activities/presentation/pages/create_post_page.dart';
import '../../features/activities/presentation/pages/post_detail_page.dart';
import '../../features/activities/domain/entities/activity_post.dart';
import '../../features/management/presentation/pages/create_patient_page.dart';
import '../../features/management/presentation/pages/patient_profile_page.dart';
import '../../features/management/presentation/pages/edit_patient_page.dart';
import '../../features/management/presentation/pages/members_page.dart';
import '../../features/management/presentation/pages/invite_member_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import 'shell_scaffold.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String myPatients = '/my-patients';
  static const String createPatient = '/create-patient';
  static const String home = '/home';
  static const String health = '/health';
  static const String medications = '/medications';
  static const String activities = '/activities';
  static const String patientProfile = '/patient-profile';
  static const String editPatient = '/edit-patient';
  static const String members = '/members';
  static const String invite = '/invite';
  static const String settings = '/settings';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.uri.path == AppRoutes.login ||
          state.uri.path == AppRoutes.register ||
          state.uri.path == AppRoutes.forgotPassword ||
          state.uri.path == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.myPatients;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.myPatients,
        builder: (context, state) => const MyPatientsPage(),
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.createPatient,
        builder: (context, state) => const CreatePatientPage(),
      ),
      GoRoute(
        path: AppRoutes.patientProfile,
        builder: (context, state) => const PatientProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editPatient,
        builder: (context, state) => const EditPatientPage(),
      ),
      GoRoute(
        path: AppRoutes.members,
        builder: (context, state) => const MembersPage(),
      ),
      GoRoute(
        path: AppRoutes.invite,
        builder: (context, state) => const InviteMemberPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),

      // Shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.health,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HealthOverviewPage(),
            ),
            routes: [
              GoRoute(
                path: 'metric/:type',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final type = state.pathParameters['type']!;
                  return HealthMetricDetailPage(metricType: type);
                },
              ),
              GoRoute(
                path: 'new-record',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final metric = state.uri.queryParameters['metric'];
                  return NewHealthRecordPage(initialMetricType: metric);
                },
              ),
              GoRoute(
                path: 'plan-config',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const HealthPlanConfigPage(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.medications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MedicationsTodayPage(),
            ),
            routes: [
              GoRoute(
                path: 'detail/:medPlanId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final medPlanId = state.pathParameters['medPlanId']!;
                  return MedicationDetailPage(
                    patientId: 'demo_patient',
                    medPlanId: medPlanId,
                  );
                },
              ),
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreateEditMedPlanPage(
                  patientId: 'demo_patient',
                ),
              ),
              GoRoute(
                path: 'search',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const MedicationSearchPage(),
              ),
              GoRoute(
                path: 'history',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const DoseHistoryPage(
                  patientId: 'demo_patient',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.activities,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ActivitiesFeedPage(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreatePostPage(),
              ),
              GoRoute(
                path: ':postId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final post = state.extra as ActivityPost;
                  return PostDetailPage(post: post);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
