package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import design.codeux.biometric_storage.BiometricStoragePlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    BiometricStoragePlugin.registerWith(registry.registrarFor("design.codeux.biometric_storage.BiometricStoragePlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
