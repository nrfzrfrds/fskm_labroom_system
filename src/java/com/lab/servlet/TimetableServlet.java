package com.lab.servlet;

import com.lab.util.DBConnection;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * TimetableServlet
 * GET /TimetableServlet?action=rooms
 *      → returns JSON array of all lab rooms
 *
 * GET /TimetableServlet?action=data&roomId=X&year=YYYY&month=MM
 *      → returns JSON with:
 *         { schedules: [...], bookings: [...] }
 *
 * schedules entries are recurring weekly classes (from lab_schedules).
 * bookings entries are one-off approved/pending bookings (from bookings table).
 *
 * Access: any logged-in user (staff, lecturer, student).
 */
// Registered in web.xml — no annotation needed (project uses explicit web.xml mappings)
public class TimetableServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Session guard — any logged-in user may view
        String user = (String) request.getSession().getAttribute("user");
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().print("{\"error\":\"Not logged in\"}");
            return;
        }

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String action = request.getParameter("action");

        if ("rooms".equals(action)) {
            // ── Return all lab rooms ──────────────────────────────────────
            StringBuilder json = new StringBuilder("[");
            String sql = "SELECT room_id, name FROM lab_rooms ORDER BY name";
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(",");
                    json.append("{")
                        .append("\"id\":").append(rs.getInt("room_id")).append(",")
                        .append("\"name\":\"").append(escapeJson(rs.getString("name"))).append("\"")
                        .append("}");
                    first = false;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            json.append("]");
            out.print(json.toString());

        } else if ("data".equals(action)) {
            // ── Return schedules + bookings for a given room + month ───────
            String roomIdParam  = request.getParameter("roomId");
            String yearParam    = request.getParameter("year");
            String monthParam   = request.getParameter("month");

            if (roomIdParam == null || yearParam == null || monthParam == null) {
                out.print("{\"error\":\"Missing parameters\"}");
                return;
            }

            int roomId, year, month;
            try {
                roomId = Integer.parseInt(roomIdParam);
                year   = Integer.parseInt(yearParam);
                month  = Integer.parseInt(monthParam);
            } catch (NumberFormatException e) {
                out.print("{\"error\":\"Invalid parameters\"}");
                return;
            }

            // Get room name
            String roomName = "";
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                         "SELECT name FROM lab_rooms WHERE room_id = ?")) {
                ps.setInt(1, roomId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) roomName = rs.getString("name");
                }
            } catch (Exception e) { e.printStackTrace(); }

            StringBuilder json = new StringBuilder("{");
            json.append("\"roomName\":\"").append(escapeJson(roomName)).append("\",");

            // ── Recurring weekly schedules ────────────────────────────────
            // day_of_week: 1=Ahad(Sun), 2=Isnin(Mon), 3=Selasa(Tue), 4=Rabu(Wed),
            //              5=Khamis(Thu), 6=Jumaat(Fri), 7=Sabtu(Sat)
            json.append("\"schedules\":[");
            String schedSql = "SELECT schedule_id, day_of_week, tahun, start_time, end_time, subject_info " +
                              "FROM lab_schedules WHERE room_id = ? ORDER BY day_of_week, start_time";
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(schedSql)) {
                ps.setInt(1, roomId);
                try (ResultSet rs = ps.executeQuery()) {
                    boolean first = true;
                    while (rs.next()) {
                        if (!first) json.append(",");
                        json.append("{")
                            .append("\"id\":").append(rs.getInt("schedule_id")).append(",")
                            .append("\"dayOfWeek\":").append(rs.getInt("day_of_week")).append(",")
                            .append("\"tahun\":").append(rs.getInt("tahun")).append(",")
                            .append("\"startTime\":\"").append(rs.getTime("start_time").toString().substring(0,5)).append("\",")
                            .append("\"endTime\":\"").append(rs.getTime("end_time").toString().substring(0,5)).append("\",")
                            .append("\"subject\":\"").append(escapeJson(rs.getString("subject_info"))).append("\"")
                            .append("}");
                        first = false;
                    }
                }
            } catch (Exception e) { e.printStackTrace(); }
            json.append("],");

            // ── One-off bookings (approved + pending) for the month ───────
            // bookings.selectedRoom matches lab_rooms.name (string-based join in this codebase)
            json.append("\"bookings\":[");
            String bookSql =
                "SELECT b.bookingID, b.dates, b.startTime, b.endTime, b.purpose, b.status, " +
                "       b.userType, COALESCE(u.name, b.userType) AS bookerName " +
                "FROM bookings b " +
                "LEFT JOIN users u ON b.userId = u.userID " +
                "WHERE b.selectedRoom = ? " +
                "  AND b.status IN ('approved','pending') " +
                "  AND YEAR(b.dates) = ? AND MONTH(b.dates) = ? " +
                "ORDER BY b.dates, b.startTime";
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(bookSql)) {
                ps.setString(1, roomName);
                ps.setInt(2, year);
                ps.setInt(3, month);
                try (ResultSet rs = ps.executeQuery()) {
                    boolean first = true;
                    while (rs.next()) {
                        if (!first) json.append(",");
                        json.append("{")
                            .append("\"id\":").append(rs.getInt("bookingID")).append(",")
                            .append("\"date\":\"").append(rs.getDate("dates").toString()).append("\",")
                            .append("\"startTime\":\"").append(rs.getTime("startTime").toString().substring(0,5)).append("\",")
                            .append("\"endTime\":\"").append(rs.getTime("endTime").toString().substring(0,5)).append("\",")
                            .append("\"purpose\":\"").append(escapeJson(rs.getString("purpose"))).append("\",")
                            .append("\"status\":\"").append(escapeJson(rs.getString("status"))).append("\",")
                            .append("\"userType\":\"").append(escapeJson(rs.getString("userType"))).append("\",")
                            .append("\"bookerName\":\"").append(escapeJson(rs.getString("bookerName"))).append("\"")
                            .append("}");
                        first = false;
                    }
                }
            } catch (Exception e) { e.printStackTrace(); }
            json.append("]}");

            out.print(json.toString());

        } else {
            out.print("{\"error\":\"Unknown action\"}");
        }
    }

    /** Minimal JSON string escaping */
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}