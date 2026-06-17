package com.lab.dao;

import com.lab.model.Booking;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class BookingDAO {

    protected Connection getConnection() {
        return com.lab.util.DBConnection.getConnection();
    }

    private boolean isLabAvailable(Booking booking) {
        String sql = "SELECT COUNT(*) FROM bookings WHERE selectedRoom = ? AND dates = ? AND (startTime < ? AND endTime > ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            java.sql.Time startTime = new java.sql.Time(booking.getStartTime().getTime());
            java.sql.Time endTime = new java.sql.Time(booking.getEndTime().getTime());

            pstmt.setString(1, booking.getSelectedRoom());
            pstmt.setDate(2, booking.getDates());
            pstmt.setTime(3, startTime);
            pstmt.setTime(4, endTime);

            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                int count = rs.getInt(1);
                return count == 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public void addBooking(Booking booking) {
        boolean isAvailable = isLabAvailable(booking);

        // FIX: Removed the "return;" so the code continues to the INSERT statement below
        if (!isAvailable) {
            booking.setStatus("rejected");
        } else {
            booking.setStatus("pending");
        }

        String sql = "INSERT INTO bookings (dates, selectedRoom, userId, userType, startTime, endTime, purpose, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            java.sql.Date date = new java.sql.Date(booking.getDates().getTime());
            java.sql.Time startDate = new java.sql.Time(booking.getStartTime().getTime());
            java.sql.Time endDate = new java.sql.Time(booking.getEndTime().getTime());

            pstmt.setDate(1, date);
            pstmt.setString(2, booking.getSelectedRoom());
            pstmt.setInt(3, booking.getUserId());
            pstmt.setString(4, booking.getUserType());
            pstmt.setTime(5, startDate);
            pstmt.setTime(6, endDate);
            pstmt.setString(7, booking.getPurpose());
            pstmt.setString(8, booking.getStatus());

            pstmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public List<Booking> getUnAvailableLab(String room) {
        List<Booking> list = new ArrayList<>();
        String sql = "SELECT dates, selectedRoom, startTime, endTime FROM bookings "
                + "WHERE status IN ('pending', 'approved') AND selectedRoom = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, room);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Booking b = new Booking();
                b.setDates(rs.getDate("dates"));
                b.setSelectedRoom(rs.getString("selectedRoom"));
                b.setStartTime(rs.getTime("startTime"));
                b.setEndTime(rs.getTime("endTime"));
                list.add(b);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Booking> getBookingsByUserId(int userId) {
        List<Booking> list = new ArrayList<>();
        String sql = "SELECT * FROM bookings WHERE userId = ? ORDER BY bookingID DESC";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Booking b = new Booking(
                        rs.getDate("dates"),
                        rs.getString("selectedRoom"),
                        rs.getInt("userId"),
                        rs.getString("userType"),
                        rs.getTime("startTime"),
                        rs.getTime("endTime"),
                        rs.getString("purpose"),
                        rs.getString("status")
                );
                b.setBookingID(rs.getInt("bookingID"));
                list.add(b);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Booking> getAllBookings() {
        List<Booking> list = new ArrayList<>();
        String sql = "SELECT * FROM bookings ORDER BY bookingID DESC";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Booking b = new Booking(
                        rs.getDate("dates"),
                        rs.getString("selectedRoom"),
                        rs.getInt("userId"),
                        rs.getString("userType"),
                        rs.getTime("startTime"),
                        rs.getTime("endTime"),
                        rs.getString("purpose"),
                        rs.getString("status")
                );
                b.setBookingID(rs.getInt("bookingID"));
                list.add(b);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public void manageBooking(int bookingID, String status) {
        String sql = "UPDATE bookings SET status = ? WHERE bookingID = ?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, bookingID);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public int getTotalBookings() {
        String sql = "SELECT COUNT(*) FROM bookings";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTotalByStatus(String status) {
        String sql = "SELECT COUNT(*) FROM bookings WHERE status = ?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public String getRecentLab(int userId) {
        String sql = "SELECT selectedRoom FROM bookings WHERE userId = ? ORDER BY bookingID DESC LIMIT 1";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getString("selectedRoom");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return "-";
    }

    public Booking getRecentBookingInfo(int userId) {
        String sql = "SELECT * FROM bookings WHERE userId = ? ORDER BY bookingID DESC LIMIT 1";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Booking b = new Booking(
                        rs.getDate("dates"),
                        rs.getString("selectedRoom"),
                        rs.getInt("userId"),
                        rs.getString("userType"),
                        rs.getTime("startTime"),
                        rs.getTime("endTime"),
                        rs.getString("purpose"),
                        rs.getString("status")
                );
                b.setBookingID(rs.getInt("bookingID"));
                return b;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public int getTotalByStatusAndUser(String status, int userId) {
        String sql = "SELECT COUNT(*) FROM bookings WHERE status = ? AND userId = ?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public List<Booking> getRecentRequests() {
        List<Booking> list = new ArrayList<>();
        String sql = "SELECT * FROM bookings ORDER BY bookingID DESC LIMIT 3";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Booking b = new Booking(
                        rs.getDate("dates"),
                        rs.getString("selectedRoom"),
                        rs.getInt("userId"),
                        rs.getString("userType"),
                        rs.getTime("startTime"),
                        rs.getTime("endTime"),
                        rs.getString("purpose"),
                        rs.getString("status")
                );
                b.setBookingID(rs.getInt("bookingID"));
                list.add(b);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean deleteBooking(int bookingID, int userId) {
        // Only deletes if the booking ID matches AND belongs to the logged-in user
        String sql = "DELETE FROM bookings WHERE bookingID = ? AND userId = ?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, bookingID);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public int getBookingCountByRoom(String roomName) {
        String sql = "SELECT COUNT(*) FROM bookings WHERE selectedRoom = ?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    /**
     * Returns a map of lab room display name -> booking count.
     * Merges variants into a single canonical name for display.
     */
    public Map<String, Integer> getLabCountsNormalized(List<String> canonicalNames) {
        // Build a direct normalised lookup: norm -> canonical display name
        Map<String, String> normToCanonical = new LinkedHashMap<>();
        for (String cn : canonicalNames) {
            normToCanonical.put(normalizeRoomName(cn), cn);
        }

        // Initialise result with canonical names at 0
        Map<String, Integer> result = new LinkedHashMap<>();
        for (String cn : canonicalNames) {
            result.put(cn, 0);
        }

        // Also collect unmatched rooms
        Map<String, Integer> unmatched = new LinkedHashMap<>();

        // GROUP BY directly from bookings
        String sql = "SELECT selectedRoom, COUNT(*) AS cnt FROM bookings GROUP BY selectedRoom";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String raw = rs.getString("selectedRoom");
                int cnt = rs.getInt("cnt");
                if (raw == null) continue;

                String norm = normalizeRoomName(raw);
                String canonical = normToCanonical.get(norm);

                if (canonical != null && result.containsKey(canonical)) {
                    result.put(canonical, result.get(canonical) + cnt);
                } else {
                    // Try short-key matching on the last 2-3 significant tokens
                    String[] tokens = norm.split("\\s+");
                    String shortKey = null;
                    if (tokens.length >= 4) {
                        shortKey = tokens[tokens.length - 3] + " " + tokens[tokens.length - 2] + " " + tokens[tokens.length - 1];
                    } else if (tokens.length >= 2) {
                        shortKey = tokens[tokens.length - 2] + " " + tokens[tokens.length - 1];
                    }
                    if (shortKey != null) {
                        for (Map.Entry<String, String> e : normToCanonical.entrySet()) {
                            String cnNorm = e.getKey();
                            if (cnNorm.equals(shortKey) || cnNorm.endsWith(" " + shortKey)) {
                                canonical = e.getValue();
                                break;
                            }
                        }
                    }

                    if (canonical != null && result.containsKey(canonical)) {
                        result.put(canonical, result.get(canonical) + cnt);
                    } else {
                        unmatched.merge(raw, cnt, Integer::sum);
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Append unmatched rooms to the result
        for (Map.Entry<String, Integer> e : unmatched.entrySet()) {
            result.put(e.getKey(), e.getValue());
        }

        return result;
    }

    /**
     * Normalize a room name so variants map to the same key.
     * Expands abbreviations, replaces roman numerals, lowercases.
     */
    private String normalizeRoomName(String name) {
        String n = name.trim();
        n = n.replaceAll("(?i)\\bLab\\b", "Laboratory");
        n = n.replaceAll("\\bI\\b", "1");
        n = n.replaceAll("\\bII\\b", "2");
        n = n.replaceAll("\\bIII\\b", "3");
        // Collapse whitespace
        n = n.replaceAll("\\s+", " ").trim();
        return n.toLowerCase();
    }

    public List<String> getDistinctLabRooms() {
        List<String> rooms = new ArrayList<>();
        String sql = "SELECT name FROM lab_rooms ORDER BY name";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rooms.add(rs.getString(1));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        // Fallback: if lab_rooms table is empty, pull from bookings so report isn't blank
        if (rooms.isEmpty()) {
            String sql2 = "SELECT DISTINCT selectedRoom FROM bookings ORDER BY selectedRoom";
            try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql2); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rooms.add(rs.getString(1));
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return rooms;
    }

    public List<Booking> getAllBookingsWithUsers() {
        List<Booking> list = new ArrayList<>();
        String sql = "SELECT b.*, u.name AS userName FROM bookings b JOIN users u ON b.userId = u.userID ORDER BY b.bookingID DESC";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Booking b = new Booking(
                        rs.getDate("dates"),
                        rs.getString("selectedRoom"),
                        rs.getInt("userId"),
                        rs.getString("userType"),
                        rs.getTime("startTime"),
                        rs.getTime("endTime"),
                        rs.getString("purpose"),
                        rs.getString("status")
                );
                b.setBookingID(rs.getInt("bookingID"));
                b.setUserName(rs.getString("userName"));
                list.add(b);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Booking> getFilteredBookingsWithUsers(String labFilter, String statusFilter, String dateFrom, String dateTo) {
        List<Booking> all = getAllBookingsWithUsers();
        List<Booking> result = new ArrayList<>();

        for (Booking b : all) {
            // Date filter
            if (dateFrom != null && !dateFrom.trim().isEmpty()) {
                java.sql.Date from = java.sql.Date.valueOf(dateFrom.trim());
                if (b.getDates() == null || b.getDates().before(from)) continue;
            }
            if (dateTo != null && !dateTo.trim().isEmpty()) {
                java.sql.Date to = java.sql.Date.valueOf(dateTo.trim());
                if (b.getDates() == null || b.getDates().after(to)) continue;
            }
            // Status filter
            if (statusFilter != null && !statusFilter.trim().isEmpty()) {
                if (b.getStatus() == null || !b.getStatus().equalsIgnoreCase(statusFilter.trim())) continue;
            }
            // Lab filter — normalize both sides to catch variants
            if (labFilter != null && !labFilter.trim().isEmpty()) {
                if (b.getSelectedRoom() == null) continue;
                String normBooking = normalizeRoomName(b.getSelectedRoom());
                String normFilter = normalizeRoomName(labFilter.trim());
                if (!normBooking.equals(normFilter)) continue;
            }
            result.add(b);
        }
        return result;
    }

    public int getTotalByPurpose(String purpose) {
        String sql = "SELECT COUNT(*) FROM bookings WHERE purpose = ?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, purpose);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTotalByUserTypeInBookings(String userType) {
        String sql = "SELECT COUNT(*) FROM bookings WHERE userType = ?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userType);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTotalDistinctUsersWithBookings() {
        String sql = "SELECT COUNT(DISTINCT userId) FROM bookings";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTotalClassSchedules() {
        String sql = "SELECT COUNT(*) FROM lab_schedules";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    /**
     * Returns a map: month-year string -> (lab room canonical name -> booking count)
     * for the bar chart — shows booking trends per lab per month.
     */
    public Map<String, Map<String, Integer>> getMonthlyBookingsByLab(List<String> canonicalNames) {
        // Same normalised lookup as getLabCountsNormalized
        Map<String, String> normToCanonical = new LinkedHashMap<>();
        for (String cn : canonicalNames) {
            normToCanonical.put(normalizeRoomName(cn), cn);
        }

        Map<String, Map<String, Integer>> result = new LinkedHashMap<>();

        String sql = "SELECT DATE_FORMAT(dates, '%Y-%m') AS monthGroup, selectedRoom, COUNT(*) AS cnt "
                   + "FROM bookings GROUP BY monthGroup, selectedRoom ORDER BY monthGroup ASC";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String month = rs.getString("monthGroup");
                String rawRoom = rs.getString("selectedRoom");
                int cnt = rs.getInt("cnt");

                String norm = normalizeRoomName(rawRoom);
                String canonical = normToCanonical.get(norm);

                if (canonical == null) {
                    String[] tokens = norm.split("\\s+");
                    String shortKey = null;
                    if (tokens.length >= 4) {
                        shortKey = tokens[tokens.length - 3] + " " + tokens[tokens.length - 2] + " " + tokens[tokens.length - 1];
                    } else if (tokens.length >= 2) {
                        shortKey = tokens[tokens.length - 2] + " " + tokens[tokens.length - 1];
                    }
                    if (shortKey != null) {
                        for (Map.Entry<String, String> e : normToCanonical.entrySet()) {
                            String cnNorm = e.getKey();
                            if (cnNorm.equals(shortKey) || cnNorm.endsWith(" " + shortKey)) {
                                canonical = e.getValue();
                                break;
                            }
                        }
                    }
                }
                if (canonical == null) canonical = rawRoom;

                result.computeIfAbsent(month, k -> new LinkedHashMap<>());
                result.get(month).merge(canonical, cnt, Integer::sum);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return result;
    }
}
