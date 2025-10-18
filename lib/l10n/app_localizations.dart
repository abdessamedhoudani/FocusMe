import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'FocusMe'**
  String get appTitle;

  /// Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// All tasks
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Add task
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// Task title
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// Task description
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get taskDescription;

  /// Select date
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Select time
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Statistics
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Task reminders
  ///
  /// In en, this message translates to:
  /// **'Task Reminders'**
  String get taskReminders;

  /// Receive notifications for scheduled tasks
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for scheduled tasks'**
  String get receiveNotifications;

  /// Notification sound
  ///
  /// In en, this message translates to:
  /// **'Notification Sound'**
  String get notificationSound;

  /// Enable sound for notifications
  ///
  /// In en, this message translates to:
  /// **'Enable sound for notifications'**
  String get enableNotificationSound;

  /// Data management
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// Reset daily tasks
  ///
  /// In en, this message translates to:
  /// **'Reset Daily Tasks'**
  String get resetDailyTasks;

  /// Mark all tasks as incomplete
  ///
  /// In en, this message translates to:
  /// **'Mark all tasks as incomplete'**
  String get markAllAsIncomplete;

  /// Delete completed tasks
  ///
  /// In en, this message translates to:
  /// **'Delete Completed Tasks'**
  String get deleteCompletedTasks;

  /// Clean up completed tasks history
  ///
  /// In en, this message translates to:
  /// **'Clean up completed tasks history'**
  String get cleanupHistory;

  /// Delete all tasks
  ///
  /// In en, this message translates to:
  /// **'Delete All Tasks'**
  String get deleteAllTasks;

  /// Clear all application data
  ///
  /// In en, this message translates to:
  /// **'Clear all application data'**
  String get clearAllData;

  /// About
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// French
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No tasks scheduled for today
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled for today'**
  String get noTasksToday;

  /// No overdue tasks
  ///
  /// In en, this message translates to:
  /// **'No overdue tasks'**
  String get noOverdueTasks;

  /// No tasks
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noTasks;

  /// Period summary
  ///
  /// In en, this message translates to:
  /// **'Period Summary'**
  String get periodSummary;

  /// Tasks created
  ///
  /// In en, this message translates to:
  /// **'Tasks Created'**
  String get tasksCreated;

  /// Tasks completed
  ///
  /// In en, this message translates to:
  /// **'Tasks Completed'**
  String get tasksCompleted;

  /// Success rate
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get successRate;

  /// Overdue tasks
  ///
  /// In en, this message translates to:
  /// **'Overdue Tasks'**
  String get overdueTasks;

  /// Task distribution
  ///
  /// In en, this message translates to:
  /// **'Task Distribution'**
  String get taskDistribution;

  /// Daily progress
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgress;

  /// Completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// Pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTasks;

  /// Overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTasksLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
