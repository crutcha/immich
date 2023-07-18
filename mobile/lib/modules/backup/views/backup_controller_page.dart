import 'dart:io';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/modules/album/providers/album.provider.dart';
import 'package:immich_mobile/modules/backup/providers/error_backup_list.provider.dart';
import 'package:immich_mobile/modules/backup/providers/ios_background_settings.provider.dart';
import 'package:immich_mobile/modules/backup/providers/manual_upload.provider.dart';
import 'package:immich_mobile/modules/backup/ui/current_backup_asset_info_box.dart';
import 'package:immich_mobile/modules/backup/models/backup_state.model.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/providers/websocket.provider.dart';
import 'package:immich_mobile/modules/backup/ui/backup_info_card.dart';

@RoutePage()
class BackupControllerPage extends HookConsumerWidget {
  const BackupControllerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BackUpState backupState = ref.watch(backupProvider);
    final hasAnyAlbum = backupState.selectedBackupAlbums.isNotEmpty;

    bool hasExclusiveAccess =
        backupState.backupProgress != BackUpProgressEnum.inBackground;
    // HERE! when sync toggle is enabled, the logic for shouldBackup needs to
    // be different.
    bool shouldBackup = backupState.allUniqueAssets.length -
                    backupState.selectedAlbumsBackupAssetsIds.length ==
                0 ||
            !hasExclusiveAccess
        ? false
        : true;

    useEffect(
      () {
        if (backupState.backupProgress != BackUpProgressEnum.inProgress &&
            backupState.backupProgress != BackUpProgressEnum.manualInProgress) {
          ref.watch(backupProvider.notifier).getBackupInfo();
        }

        // Update the background settings information just to make sure we
        // have the latest, since the platform channel will not update
        // automatically
        if (Platform.isIOS) {
          ref.watch(iOSBackgroundSettingsProvider.notifier).refresh();
        }

        ref
            .watch(websocketProvider.notifier)
            .stopListenToEvent('on_upload_success');
        return null;
      },
      [],
    );

<<<<<<< HEAD
=======
    Future<void> performDeletion(List<Asset> assets) async {
      try {
        checkInProgress.value = true;
        ImmichToast.show(
          context: context,
          msg: "Deleting ${assets.length} assets on the server...",
        );
        await ref
            .read(assetProvider.notifier)
            .deleteAssets(assets, force: true);
        ImmichToast.show(
          context: context,
          msg: "Deleted ${assets.length} assets on the server. "
              "You can now start a manual backup",
          toastType: ToastType.success,
        );
      } finally {
        checkInProgress.value = false;
      }
    }

    void performBackupCheck() async {
      try {
        checkInProgress.value = true;
        if (backupState.allUniqueAssets.length >
            backupState.selectedAlbumsBackupAssetsIds.length) {
          ImmichToast.show(
            context: context,
            msg: "Backup all assets before starting this check!",
            toastType: ToastType.error,
          );
          return;
        }
        final connection = await Connectivity().checkConnectivity();
        if (connection != ConnectivityResult.wifi) {
          ImmichToast.show(
            context: context,
            msg: "Make sure to be connected to unmetered Wi-Fi",
            toastType: ToastType.error,
          );
          return;
        }
        WakelockPlus.enable();
        const limit = 100;
        final toDelete = await ref
            .read(backupVerificationServiceProvider)
            .findWronglyBackedUpAssets(limit: limit);
        if (toDelete.isEmpty) {
          ImmichToast.show(
            context: context,
            msg: "Did not find any corrupt asset backups!",
            toastType: ToastType.success,
          );
        } else {
          await showDialog(
            context: context,
            builder: (context) => ConfirmDialog(
              onOk: () => performDeletion(toDelete),
              title: "Corrupt backups!",
              ok: "Delete",
              content:
                  "Found ${toDelete.length} (max $limit at once) corrupt asset backups. "
                  "Run the check again to find more.\n"
                  "Do you want to delete the corrupt asset backups now?",
            ),
          );
        }
      } finally {
        WakelockPlus.disable();
        checkInProgress.value = false;
      }
    }

    Widget buildCheckCorruptBackups() {
      return ListTile(
        leading: Icon(
          Icons.warning_rounded,
          color: context.primaryColor,
        ),
        title: const Text(
          "Check for corrupt asset backups",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        isThreeLine: true,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Run this check only over Wi-Fi and once all assets "
                "have been backed-up. The procedure might take a few minutes."),
            ElevatedButton(
              onPressed: checkInProgress.value ? null : performBackupCheck,
              child: checkInProgress.value
                  ? const CircularProgressIndicator()
                  : const Text("Perform check"),
            ),
          ],
        ),
      );
    }

    Widget buildStorageInformation() {
      return ListTile(
        leading: Icon(
          Icons.storage_rounded,
          color: Theme.of(context).primaryColor,
        ),
        title: const Text(
          "backup_controller_page_server_storage",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ).tr(),
        isThreeLine: true,
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                  minHeight: 10.0,
                  value: backupState.serverInfo.diskUsagePercentage / 100.0,
                  backgroundColor: Colors.grey,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: const Text('backup_controller_page_storage_format').tr(
                  args: [
                    backupState.serverInfo.diskUse,
                    backupState.serverInfo.diskSize
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    ListTile buildAutoBackupController() {
      final isAutoBackup = backupState.autoBackup;
      final backUpOption = isAutoBackup
          ? "backup_controller_page_status_on".tr()
          : "backup_controller_page_status_off".tr();
      final backupBtnText = isAutoBackup
          ? "backup_controller_page_turn_off".tr()
          : "backup_controller_page_turn_on".tr();
      return ListTile(
        isThreeLine: true,
        leading: isAutoBackup
            ? Icon(
                Icons.cloud_done_rounded,
                color: context.primaryColor,
              )
            : const Icon(Icons.cloud_off_rounded),
        title: Text(
          backUpOption,
          style: context.textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isAutoBackup)
                const Text(
                  "backup_controller_page_desc_backup",
                  style: TextStyle(fontSize: 14),
                ).tr(),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(backupProvider.notifier)
                      .setAutoBackup(!isAutoBackup),
                  child: Text(
                    backupBtnText,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.isDarkTheme ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void showErrorToUser(String msg) {
      final snackBar = SnackBar(
        content: Text(
          msg.tr(),
        ),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    void showBatteryOptimizationInfoToUser() {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'backup_controller_page_background_battery_info_title',
            ).tr(),
            content: SingleChildScrollView(
              child: const Text(
                'backup_controller_page_background_battery_info_message',
              ).tr(),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => launchUrl(
                  Uri.parse('https://dontkillmyapp.com'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(
                  "backup_controller_page_background_battery_info_link",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ).tr(),
              ),
              ElevatedButton(
                child: const Text(
                  'backup_controller_page_background_battery_info_ok',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ).tr(),
                onPressed: () {
                  context.pop();
                },
              ),
            ],
          );
        },
      );
    }

    Widget buildSyncController() {
      //final isSyncEnabled = useState(backupState.sync);
      final bool isSyncEnabled = backupState.sync;
      final Color activeColor = Theme.of(context).primaryColor;

      return Column(
        children: [
          ListTile(
            isThreeLine: true,
            leading: isSyncEnabled
                ? Icon(
              Icons.sync,
              color: activeColor,
            )
                : const Icon(Icons.sync_disabled),
            title: Text(
              isSyncEnabled
                  ? "Sync mode is enabled"
                  : "Sync mode is disabled",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ).tr(),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSyncEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: const Text(
                      "backup_controller_page_background_description",
                    ).tr(),
                  ),
                if (isSyncEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: const Text(
                        "Sync mode will delete assets from Immich that do not exist on your phone",
                    ).tr(),
                  ),
                ElevatedButton(
                  onPressed: () => ref
                      .read(backupProvider.notifier)
                      .setSync(!isSyncEnabled),
                  child: Text(
                    isSyncEnabled
                        ? "Turn off sync mode"
                        : "Turn on sync mode",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ).tr(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildBackgroundBackupController() {
      final bool isBackgroundEnabled = backupState.backgroundBackup;
      final bool isWifiRequired = backupState.backupRequireWifi;
      final bool isChargingRequired = backupState.backupRequireCharging;
      final Color activeColor = context.primaryColor;

      String formatBackupDelaySliderValue(double v) {
        if (v == 0.0) {
          return 'setting_notifications_notify_seconds'.tr(args: const ['5']);
        } else if (v == 1.0) {
          return 'setting_notifications_notify_seconds'.tr(args: const ['30']);
        } else if (v == 2.0) {
          return 'setting_notifications_notify_minutes'.tr(args: const ['2']);
        } else {
          return 'setting_notifications_notify_minutes'.tr(args: const ['10']);
        }
      }

      int backupDelayToMilliseconds(double v) {
        if (v == 0.0) {
          return 5000;
        } else if (v == 1.0) {
          return 30000;
        } else if (v == 2.0) {
          return 120000;
        } else {
          return 600000;
        }
      }

      double backupDelayToSliderValue(int ms) {
        if (ms == 5000) {
          return 0.0;
        } else if (ms == 30000) {
          return 1.0;
        } else if (ms == 120000) {
          return 2.0;
        } else {
          return 3.0;
        }
      }

      final triggerDelay =
          useState(backupDelayToSliderValue(backupState.backupTriggerDelay));

      return Column(
        children: [
          ListTile(
            isThreeLine: true,
            leading: isBackgroundEnabled
                ? Icon(
                    Icons.cloud_sync_rounded,
                    color: activeColor,
                  )
                : const Icon(Icons.cloud_sync_rounded),
            title: Text(
              isBackgroundEnabled
                  ? "backup_controller_page_background_is_on"
                  : "backup_controller_page_background_is_off",
              style: context.textTheme.titleSmall,
            ).tr(),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isBackgroundEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: const Text(
                      "backup_controller_page_background_description",
                    ).tr(),
                  ),
                if (isBackgroundEnabled && Platform.isAndroid)
                  SwitchListTile.adaptive(
                    title: const Text("backup_controller_page_background_wifi")
                        .tr(),
                    secondary: Icon(
                      Icons.wifi,
                      color: isWifiRequired ? activeColor : null,
                    ),
                    dense: true,
                    activeColor: activeColor,
                    value: isWifiRequired,
                    onChanged: (isChecked) => ref
                        .read(backupProvider.notifier)
                        .configureBackgroundBackup(
                          requireWifi: isChecked,
                          onError: showErrorToUser,
                          onBatteryInfo: showBatteryOptimizationInfoToUser,
                        ),
                  ),
                if (isBackgroundEnabled)
                  SwitchListTile.adaptive(
                    title:
                        const Text("backup_controller_page_background_charging")
                            .tr(),
                    secondary: Icon(
                      Icons.charging_station,
                      color: isChargingRequired ? activeColor : null,
                    ),
                    dense: true,
                    activeColor: activeColor,
                    value: isChargingRequired,
                    onChanged: (isChecked) => ref
                        .read(backupProvider.notifier)
                        .configureBackgroundBackup(
                          requireCharging: isChecked,
                          onError: showErrorToUser,
                          onBatteryInfo: showBatteryOptimizationInfoToUser,
                        ),
                  ),
                if (isBackgroundEnabled && Platform.isAndroid)
                  ListTile(
                    isThreeLine: false,
                    dense: true,
                    title: const Text(
                      'backup_controller_page_background_delay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ).tr(
                      args: [formatBackupDelaySliderValue(triggerDelay.value)],
                    ),
                    subtitle: Slider(
                      value: triggerDelay.value,
                      onChanged: (double v) => triggerDelay.value = v,
                      onChangeEnd: (double v) => ref
                          .read(backupProvider.notifier)
                          .configureBackgroundBackup(
                            triggerDelay: backupDelayToMilliseconds(v),
                            onError: showErrorToUser,
                            onBatteryInfo: showBatteryOptimizationInfoToUser,
                          ),
                      max: 3.0,
                      divisions: 3,
                      label: formatBackupDelaySliderValue(triggerDelay.value),
                      activeColor: context.primaryColor,
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => ref
                      .read(backupProvider.notifier)
                      .configureBackgroundBackup(
                        enabled: !isBackgroundEnabled,
                        onError: showErrorToUser,
                        onBatteryInfo: showBatteryOptimizationInfoToUser,
                      ),
                  child: Text(
                    isBackgroundEnabled
                        ? "backup_controller_page_background_turn_off"
                        : "backup_controller_page_background_turn_on",
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.isDarkTheme ? Colors.black : Colors.white,
                    ),
                  ).tr(),
                ),
              ],
            ),
          ),
          if (isBackgroundEnabled && Platform.isIOS)
            FutureBuilder(
              future: ref
                  .read(backgroundServiceProvider)
                  .getIOSBackgroundAppRefreshEnabled(),
              builder: (context, snapshot) {
                final enabled = snapshot.data;
                // If it's not enabled, show them some kind of alert that says
                // background refresh is not enabled
                if (enabled != null && !enabled) {}
                // If it's enabled, no need to bother them
                return Container();
              },
            ),
          if (Platform.isIOS && isBackgroundEnabled && settings != null)
            IosDebugInfoTile(
              settings: settings,
            ),
        ],
      );
    }

    Widget buildBackgroundAppRefreshWarning() {
      return ListTile(
        isThreeLine: true,
        leading: const Icon(
          Icons.task_outlined,
        ),
        title: const Text(
          'backup_controller_page_background_app_refresh_disabled_title',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ).tr(),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Text(
                'backup_controller_page_background_app_refresh_disabled_content',
              ).tr(),
            ),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text(
                'backup_controller_page_background_app_refresh_enable_button_text',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ).tr(),
            ),
          ],
        ),
      );
    }

>>>>>>> e4d9d33d (add sync mode toggle on backup page)
    Widget buildSelectedAlbumName() {
      var text = "backup_controller_page_backup_selected".tr();
      var albums = ref.watch(backupProvider).selectedBackupAlbums;

      if (albums.isNotEmpty) {
        for (var album in albums) {
          if (album.name == "Recent" || album.name == "Recents") {
            text += "${album.name} (${'backup_all'.tr()}), ";
          } else {
            text += "${album.name}, ";
          }
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            text.trim().substring(0, text.length - 2),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.primaryColor,
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "backup_controller_page_none_selected".tr(),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.primaryColor,
            ),
          ),
        );
      }
    }

    Widget buildExcludedAlbumName() {
      var text = "backup_controller_page_excluded".tr();
      var albums = ref.watch(backupProvider).excludedBackupAlbums;

      if (albums.isNotEmpty) {
        for (var album in albums) {
          text += "${album.name}, ";
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            text.trim().substring(0, text.length - 2),
            style: context.textTheme.labelLarge?.copyWith(
              color: Colors.red[300],
            ),
          ),
        );
      } else {
        return const SizedBox();
      }
    }

    buildFolderSelectionTile() {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: context.isDarkTheme
                  ? const Color.fromARGB(255, 56, 56, 56)
                  : Colors.black12,
              width: 1,
            ),
          ),
          elevation: 0,
          borderOnForeground: false,
          child: ListTile(
            minVerticalPadding: 18,
            title: Text(
              "backup_controller_page_albums",
              style: context.textTheme.titleMedium,
            ).tr(),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "backup_controller_page_to_backup",
                    style: context.textTheme.bodyMedium,
                  ).tr(),
                  buildSelectedAlbumName(),
                  buildExcludedAlbumName(),
                ],
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () async {
                await context.pushRoute(const BackupAlbumSelectionRoute());
                // waited until returning from selection
                await ref
                    .read(backupProvider.notifier)
                    .backupAlbumSelectionDone();
                // waited until backup albums are stored in DB
                ref.read(albumProvider.notifier).getDeviceAlbums();
              },
              child: const Text(
                "backup_controller_page_select",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ).tr(),
            ),
          ),
        ),
      );
    }

    void startBackup() {
      ref.watch(errorBackupListProvider.notifier).empty();
      if (ref.watch(backupProvider).backupProgress !=
          BackUpProgressEnum.inBackground) {
        ref.watch(backupProvider.notifier).startBackupProcess();
      }
    }

    Widget buildBackupButton() {
      return Padding(
        padding: const EdgeInsets.only(
          top: 24,
        ),
        child: Container(
          child: backupState.backupProgress == BackUpProgressEnum.inProgress ||
                  backupState.backupProgress ==
                      BackUpProgressEnum.manualInProgress
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.grey[50],
                    backgroundColor: Colors.red[300],
                    // padding: const EdgeInsets.all(14),
                  ),
                  onPressed: () {
                    if (backupState.backupProgress ==
                        BackUpProgressEnum.manualInProgress) {
                      ref.read(manualUploadProvider.notifier).cancelBackup();
                    } else {
                      ref.read(backupProvider.notifier).cancelBackup();
                    }
                  },
                  child: const Text(
                    "backup_controller_page_cancel",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ).tr(),
                )
              : ElevatedButton(
                  onPressed: shouldBackup ? startBackup : null,
                  child: const Text(
                    "backup_controller_page_start_backup",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ).tr(),
                ),
        ),
      );
    }

    buildBackgroundBackupInfo() {
      return const ListTile(
        leading: Icon(Icons.info_outline_rounded),
        title: Text(
          "Background backup is currently running, cannot start manual backup",
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "backup_controller_page_backup",
        ).tr(),
        leading: IconButton(
          onPressed: () {
            ref.watch(websocketProvider.notifier).listenUploadEvent();
            context.popRoute(true);
          },
          splashRadius: 24,
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () => context.pushRoute(const BackupOptionsRoute()),
              splashRadius: 24,
              icon: const Icon(
                Icons.settings_outlined,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 32),
        child: ListView(
          // crossAxisAlignment: CrossAxisAlignment.start,
<<<<<<< HEAD
          children: hasAnyAlbum
              ? [
                  buildFolderSelectionTile(),
                  BackupInfoCard(
                    title: "backup_controller_page_total".tr(),
                    subtitle: "backup_controller_page_total_sub".tr(),
                    info: ref.watch(backupProvider).availableAlbums.isEmpty
                        ? "..."
                        : "${backupState.allUniqueAssets.length}",
                  ),
                  BackupInfoCard(
                    title: "backup_controller_page_backup".tr(),
                    subtitle: "backup_controller_page_backup_sub".tr(),
                    info: ref.watch(backupProvider).availableAlbums.isEmpty
                        ? "..."
                        : "${backupState.selectedAlbumsBackupAssetsIds.length}",
                  ),
                  BackupInfoCard(
                    title: "backup_controller_page_remainder".tr(),
                    subtitle: "backup_controller_page_remainder_sub".tr(),
                    info: ref.watch(backupProvider).availableAlbums.isEmpty
                        ? "..."
                        : "${max(0, backupState.allUniqueAssets.length - backupState.selectedAlbumsBackupAssetsIds.length)}",
                  ),
                  const Divider(),
                  const CurrentUploadingAssetInfoBox(),
                  if (!hasExclusiveAccess) buildBackgroundBackupInfo(),
                  buildBackupButton(),
                ]
              : [buildFolderSelectionTile()],
=======
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                "backup_controller_page_info",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ).tr(),
            ),
            buildFolderSelectionTile(),
            BackupInfoCard(
              title: "backup_controller_page_total".tr(),
              subtitle: "backup_controller_page_total_sub".tr(),
              info: ref.watch(backupProvider).availableAlbums.isEmpty
                  ? "..."
                  : "${backupState.allUniqueAssets.length}",
            ),
            BackupInfoCard(
              title: "backup_controller_page_backup".tr(),
              subtitle: "backup_controller_page_backup_sub".tr(),
              info: ref.watch(backupProvider).availableAlbums.isEmpty
                  ? "..."
                  : "${backupState.selectedAlbumsBackupAssetsIds.length}",
            ),
            BackupInfoCard(
              title: "backup_controller_page_remainder".tr(),
              subtitle: "backup_controller_page_remainder_sub".tr(),
              info: ref.watch(backupProvider).availableAlbums.isEmpty
                  ? "..."
                  : "${backupState.allUniqueAssets.length - backupState.selectedAlbumsBackupAssetsIds.length}",
            ),
            const Divider(),
            buildAutoBackupController(),
            const Divider(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Platform.isIOS
                  ? (appRefreshDisabled
                      ? buildBackgroundAppRefreshWarning()
                      : buildBackgroundBackupController())
                  : buildBackgroundBackupController(),
            ),
            if (showBackupFix) const Divider(),
            if (showBackupFix) buildCheckCorruptBackups(),
            const Divider(),
            buildSyncController(),
            const Divider(),
            buildStorageInformation(),
            const Divider(),
            const CurrentUploadingAssetInfoBox(),
            if (!hasExclusiveAccess) buildBackgroundBackupInfo(),
            buildBackupButton()
          ],
>>>>>>> e4d9d33d (add sync mode toggle on backup page)
        ),
      ),
    );
  }
}
