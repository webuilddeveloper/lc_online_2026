class ApiConfig {
  const ApiConfig._();

  static const versionName = '4.1.8';
  static const versionNumber = 418;

  // static const apiBaseUrl = 'https://lc.we-builds.com/lc-api/';
  // static const apiBaseUrl = 'http://localhost:7200';
  static const apiBaseUrl = 'https://2f8c-125-26-172-229.ngrok-free.app';
  static const apiLC = 'https://lc.we-builds.com/lc-api/';
  static const documentUploadUrl =
      'https://lc.we-builds.com/lc-document/upload';
  static const lineNotifyUrl = 'https://notify-api.line.me/api/notify';
  static const otpBaseUrl = 'https://portal-otp.smsmkt.com/api/';
  static const electionLcBaseUrl = 'http://122.155.223.63/td-election-lc-api/';

  // TODO: Replace this with the team's stable auth API host when ready.
  // static const authBaseUrl = 'http://localhost:7200';
  static const authBaseUrl = 'https://2f8c-125-26-172-229.ngrok-free.app';
}