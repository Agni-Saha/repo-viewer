/*
CORE:
Github returns the repositories in a bacth - like 30 (by default) at a time.
We can definitely change this number while making the API call, but instead
lets make it constant throughout the app. In this way, we'll know how much
data have we got from one API request.
*/

class PaginationConfig {
  static const int itemsPerPage = 30;
}
