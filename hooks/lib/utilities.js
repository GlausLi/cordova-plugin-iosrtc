
/**
 * Utilities and shared functionality for the build hooks.
 */

var path = require("path");

module.exports = {

    /**
     * Used to get the path to the XCode project's .pbxproj file.
     *
     * @param {object} context - The Cordova context.
     * @returns The path to the XCode project's .pbxproj file.
     */
    getXcodeProjectPath: function(context) {
        return path.join("platforms", "ios", "LinguSocial.xcodeproj", "project.pbxproj");
    }
};
