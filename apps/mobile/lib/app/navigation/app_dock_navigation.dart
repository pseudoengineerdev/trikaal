import 'package:flutter/material.dart';

import '../state/birth_input_state.dart';
import '../widgets/universal_dock_scaffold.dart';
import '../../features/features/presentation/features_grid_page.dart';
import '../../features/hindu_calendar/presentation/hindu_calendar_page.dart';
import '../../features/learning/presentation/learning_modules_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/subscription/presentation/subscription_page.dart';

/// Opens the Hindu calendar feature page; wired to the calendar icon in the
/// primary app bar.
void openHinduCalendar(BuildContext context, BirthInputState birthInputState) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return HinduCalendarPage(birthInputState: birthInputState);
      },
    ),
  );
}

/// Opens the subscription page; wired to the premium icon in the primary
/// app bar on screens without their own dock handler.
void openSubscription(BuildContext context, BirthInputState birthInputState) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return SubscriptionPage(birthInputState: birthInputState);
      },
    ),
  );
}

enum DockHomeBehavior {
  stay,
  popOne,
  popToRoot,
}

enum DockChartsBehavior {
  stay,
  pushFeatures,
  popOne,
}

void handleAppDockSelection({
  required BuildContext context,
  required AppDockItem tappedItem,
  required AppDockItem activeItem,
  required BirthInputState birthInputState,
  DockHomeBehavior homeBehavior = DockHomeBehavior.popToRoot,
  DockChartsBehavior chartsBehavior = DockChartsBehavior.pushFeatures,
  String menuComingSoonMessage = 'This tab will be finalized next.',
}) {
  switch (tappedItem) {
    case AppDockItem.home:
      _applyHomeBehavior(context, homeBehavior);
      return;
    case AppDockItem.profile:
      if (activeItem == AppDockItem.profile) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return ProfilePage(birthInputState: birthInputState);
          },
        ),
      );
      return;
    case AppDockItem.charts:
      _applyChartsBehavior(
        context,
        activeItem: activeItem,
        chartsBehavior: chartsBehavior,
        birthInputState: birthInputState,
      );
      return;
    case AppDockItem.premium:
      if (activeItem == AppDockItem.premium) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return SubscriptionPage(birthInputState: birthInputState);
          },
        ),
      );
      return;
    case AppDockItem.learning:
      if (activeItem == AppDockItem.learning) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return LearningModulesPage(birthInputState: birthInputState);
          },
        ),
      );
      return;
    case AppDockItem.menu:
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(menuComingSoonMessage)),
        );
      return;
  }
}

void _applyHomeBehavior(BuildContext context, DockHomeBehavior behavior) {
  switch (behavior) {
    case DockHomeBehavior.stay:
      return;
    case DockHomeBehavior.popOne:
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    case DockHomeBehavior.popToRoot:
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
  }
}

void _applyChartsBehavior(
  BuildContext context, {
  required AppDockItem activeItem,
  required DockChartsBehavior chartsBehavior,
  required BirthInputState birthInputState,
}) {
  if (activeItem == AppDockItem.charts &&
      chartsBehavior == DockChartsBehavior.stay) {
    return;
  }

  switch (chartsBehavior) {
    case DockChartsBehavior.stay:
      return;
    case DockChartsBehavior.popOne:
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    case DockChartsBehavior.pushFeatures:
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return FeaturesGridPage(birthInputState: birthInputState);
          },
        ),
      );
      return;
  }
}
