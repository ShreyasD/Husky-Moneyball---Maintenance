// Ionic Starter App

// angular.module is a global place for creating, registering and retrieving Angular modules
// 'ActivityTrackingApp' is the name of this angular module example (also set in a <body> attribute in index.html)
// the 2nd parameter is an array of 'requires'
// 'ActivityTrackingApp.services' is found in services.js
// 'ActivityTrackingApp.controllers' is found in controllers.js
angular.module('ActivityTrackingApp', ['ionic', 'ActivityTrackingApp.controllers', 'ActivityTrackingApp.services'])

.run(function($ionicPlatform) {
  $ionicPlatform.ready(function() {
    // Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
    // for form inputs)
    if (window.cordova && window.cordova.plugins && window.cordova.plugins.Keyboard) {
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
      cordova.plugins.Keyboard.disableScroll(true);

    }
    if (window.StatusBar) {
      // org.apache.cordova.statusbar required
      StatusBar.styleLightContent();
    }
  });
})

.config(function($stateProvider, $urlRouterProvider, $ionicConfigProvider) {

  //Configure Ionic UI
  $ionicConfigProvider.tabs.position('top');

  // Ionic uses AngularUI Router which uses the concept of states
  // Learn more here: https://github.com/angular-ui/ui-router
  // Set up the various states which the app can be in.
  // Each state's controller can be found in controllers.js
  $stateProvider

  // setup an abstract state for the tabs directive
  .state('ActivityTracking', {
    url: '/ActivityTracking',
    abstract: true,
    templateUrl: 'apex/VTTM_ActivityTrackingDemoTabs'
  })

  // Each tab has its own nav history stack:

  .state('ActivityTracking.Activities', {
    url: '/Activities',
    views: {
      'ActivityTracking-Activities': {
        templateUrl: 'apex/VTTM_ActivityTrackingDemoActivities',
        controller: 'ActivitiesCtrl'
      }
    }
  })

  .state('ActivityTracking.Calendar', {
    url: '/Calendar',
    views: {
      'ActivityTracking-Calendar': {
        templateUrl: 'apex/VTTM_ActivityTrackingDemoCalendar',
        controller: 'CalendarCtrl'
      }
    }
  })

  .state('ActivityTracking.ActivityDetail', {
    url: '/Activities/:activityId',
    views: {
      'ActivityTracking-Activities': {
        templateUrl: 'apex/VTTM_ActivityTrackingDemoAcivityDetail',
        controller: 'ActivityDetailCtrl'
      }
    }
  });

  // if none of the above states are matched, use this as the fallback
  $urlRouterProvider.otherwise('/ActivityTracking/Activities');

});
