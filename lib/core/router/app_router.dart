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
import '../../features/home/presentation/pages/full_history_page.dart';
import '../../features/home/presentation/pages/up_next_page.dart';
import '../../features/health/presentation/pages/health_overview_page.dart';
import '../../features/health/presentation/pages/health_metric_detail_page.dart';
import '../../features/health/presentation/pages/new_health_record_page.dart';
import '../../features/health/presentation/pages/health_plan_config_page.dart';
import '../../features/medications/presentation/pages/medications_today_page.dart';
import '../../features/medications/presentation/pages/medication_detail_page.dart';
import '../../features/medications/presentation/pages/create_edit_med_plan_page.dart';
import '../../features/medications/presentation/pages/medication_search_page.dart';
import '../../features/medications/presentation/pages/dose_history_page.dart';
import '../../features/medications/presentation/pages/med_plan_list_page.dart';
import '../../features/activities/presentation/pages/activities_feed_page.dart';
import '../../features/activities/presentation/pages/create_post_page.dart';
import '../../features/activities/presentation/pages/post_detail_page.dart';
import '../../features/activities/presentation/pages/activity_plan_list_page.dart';
import '../../features/activities/presentation/pages/create_edit_activity_plan_page.dart';
import '../../features/activities/domain/entities/activity_post.dart';
import '../../features/activities/domain/entities/activity_plan_item.dart';
import '../../features/management/presentation/pages/create_patient_page.dart';
import '../../features/management/presentation/pages/patient_profile_page.dart';
import '../../features/management/presentation/pages/edit_patient_page.dart';
import '../../features/management/presentation/pages/members_page.dart';
import '../../features/management/presentation/pages/invite_member_page.dart';
import '../../features/management/presentation/pages/accept_invite_page.dart';
import '../../features/exams/presentation/pages/exam_list_page.dart';
import '../../features/exams/presentation/pages/exam_detail_page.dart';
import '../../features/exams/presentation/pages/create_edit_exam_page.dart';
import '../../features/exams/domain/entities/clinical_exam.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';
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
  static const String acceptInvite = '/accept-invite';
  static const String exams = '/exams';
  static const String fullHistory = '/history';
  static const String upNext = '/up-next';
  static const String settings = '/settings';
  static const String editProfile = '/settings/edit-profile';
  static const String about = '/settings/about';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<T> _slideTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideIn = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final fadeIn = Tween(begin: 0.85, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));

      final slideOut = Tween(
        begin: Offset.zero,
        end: const Offset(-0.3, 0.0),
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: secondaryAnimation.drive(slideOut),
        child: SlideTransition(
          position: animation.drive(slideIn),
          child: FadeTransition(
            opacity: animation.drive(fadeIn),
            child: child,
          ),
        ),
      );
    },
  );
}

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
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MyPatientsPage(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Parallax-style pop effect: MyPatientsPage slides in from the
            // left at 1/3 speed (parallax) while the leaving page slides out
            // to the right at full speed.
            final slideIn = Tween(
              begin: const Offset(-0.3, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            final fadeIn = Tween(begin: 0.7, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut));

            return SlideTransition(
              position: animation.drive(slideIn),
              child: FadeTransition(
                opacity: animation.drive(fadeIn),
                child: child,
              ),
            );
          },
        ),
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.createPatient,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const CreatePatientPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.patientProfile,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const PatientProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editPatient,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const EditPatientPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.members,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const MembersPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.invite,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const InviteMemberPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.acceptInvite,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const AcceptInvitePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.fullHistory,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const FullHistoryPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.upNext,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const UpNextPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.exams,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const ExamListPage(),
        ),
        routes: [
          GoRoute(
            path: 'create',
            pageBuilder: (context, state) => _slideTransitionPage(
              state: state,
              child: CreateEditExamPage(existing: state.extra as ClinicalExam?),
            ),
          ),
          GoRoute(
            path: ':examId',
            pageBuilder: (context, state) => _slideTransitionPage(
              state: state,
              child: ExamDetailPage(exam: state.extra as ClinicalExam),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const EditProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.about,
        pageBuilder: (context, state) => _slideTransitionPage(
          state: state,
          child: const AboutPage(),
        ),
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
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: HealthMetricDetailPage(metricType: state.pathParameters['type']!),
                ),
              ),
              GoRoute(
                path: 'new-record',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: NewHealthRecordPage(initialMetricType: state.uri.queryParameters['metric']),
                ),
              ),
              GoRoute(
                path: 'plan-config',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: const HealthPlanConfigPage(),
                ),
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
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: MedicationDetailPage(
                    patientId: state.uri.queryParameters['patientId'] ?? '',
                    medPlanId: state.pathParameters['medPlanId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: CreateEditMedPlanPage(
                    patientId: state.uri.queryParameters['patientId'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: 'search',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: const MedicationSearchPage(),
                ),
              ),
              GoRoute(
                path: 'history',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: DoseHistoryPage(
                    patientId: state.uri.queryParameters['patientId'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: 'plan-config',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: const MedPlanListPage(),
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
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: CreatePostPage(prefill: state.extra as ActivityPost?),
                ),
              ),
              GoRoute(
                path: 'plan-config',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: const ActivityPlanListPage(),
                ),
              ),
              GoRoute(
                path: 'plan-create',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: CreateEditActivityPlanPage(
                    existing: state.extra as ActivityPlanItem?,
                  ),
                ),
              ),
              GoRoute(
                path: ':postId',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideTransitionPage(
                  state: state,
                  child: PostDetailPage(post: state.extra as ActivityPost),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
