import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class MeetingRequestService {
  // Create a new meeting request
  static Future<Map<String, dynamic>> createMeetingRequest({
    required String volunteerId,
    required List<Map<String, String>> preferredSlots,
    required String token,
  }) async {
    try {
      print("createMeetingRequest");
      print("volunteerId: $volunteerId");
      print("preferredSlots: $preferredSlots");
      print("token: $token");
      final response = await http.post(
        Uri.parse(meetingRequests),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'volunteerId': volunteerId,
          'preferredSlots': preferredSlots,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['meetingRequest']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create meeting request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get all meeting requests for the authenticated user
  static Future<Map<String, dynamic>> getMeetingRequests({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(meetingRequests),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['meetingRequests']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get meeting requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get a specific meeting request
  static Future<Map<String, dynamic>> getMeetingRequestById({
    required String meetingId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$meetingRequests/$meetingId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['meetingRequest']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get meeting request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Volunteer selects a time slot
  static Future<Map<String, dynamic>> selectTimeSlot({
    required String meetingId,
    required int selectedSlotIndex,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$meetingRequests/$meetingId/select-time'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'selectedSlotIndex': selectedSlotIndex}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': {
            'meetingRequest': data['meetingRequest'],
            'zoomMeeting': data['zoomMeeting'],
          },
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to select time slot',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Volunteer rejects a meeting request
  static Future<Map<String, dynamic>> rejectMeetingRequest({
    required String meetingId,
    required String rejectReason,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$meetingRequests/$meetingId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rejectReason': rejectReason}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['meetingRequest']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reject meeting request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get meeting requests for a volunteer
  static Future<Map<String, dynamic>> getVolunteerMeetingRequests({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(volunteerMeetingRequests),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['meetingRequests']};
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? 'Failed to get volunteer meeting requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get meeting requests created by a user
  static Future<Map<String, dynamic>> getUserMeetingRequests({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(userMeetingRequests),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['meetingRequests']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user meeting requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
