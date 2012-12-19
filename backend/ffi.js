function addAttribute(k, v, id) {
  $('#' + id).attr(k, v);
}
function refreshListview(id) {
  $('#' + id).listview('refresh');
}
