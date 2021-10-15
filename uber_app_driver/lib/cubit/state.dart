abstract class MainState {}

class LoginInitialState extends MainState {}

class IsPasswordChangeState extends MainState {}

class LoginLoadingState extends MainState {}

class LoginSuccessState extends MainState {}

class LoginErrorState extends MainState {
  final String error;
  LoginErrorState(this.error);
}

class RegisterLoadingState extends MainState {}

class RegisterSuccessState extends MainState {}

class RegisterErrorState extends MainState {
  final String error;
  RegisterErrorState(this.error);
}

class PickUpLocationState extends MainState {}

class DropOffLocationState extends MainState {}

class FindPlaceState extends MainState {}

class CarInfoLoadingState extends MainState {}

class CarInfoSuccessState extends MainState {}

class CarInfoErrorState extends MainState {
  final String error;
  CarInfoErrorState(this.error);
}

class UpdateEarningsState extends MainState {}

class UpdateTripsState extends MainState {}

class UpdateTripHistoryData extends MainState {}
