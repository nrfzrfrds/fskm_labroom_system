package com.lab.servlet;

import com.lab.dao.ScheduleDAO;
import com.lab.model.Schedule;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Time;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/ScheduleServlet")
public class ScheduleServlet extends HttpServlet {

    // --- THIS METHOD SENDS THE BLOCKED TIMES TO THE JSP ---
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String roomId = request.getParameter("roomId");
        String dayOfWeek = request.getParameter("dayOfWeek");
        String excludeId = request.getParameter("excludeId");

        if (roomId != null && dayOfWeek != null) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();

            String sql = "SELECT start_time, end_time FROM lab_schedules WHERE room_id = ? AND day_of_week = ?";
            if (excludeId != null && !excludeId.trim().isEmpty() && !excludeId.equals("0")) {
                sql += " AND schedule_id != ?";
            }

            StringBuilder json = new StringBuilder("[");
            try (Connection conn = com.lab.util.DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                
                ps.setInt(1, Integer.parseInt(roomId));
                ps.setInt(2, Integer.parseInt(dayOfWeek));
                if (excludeId != null && !excludeId.trim().isEmpty() && !excludeId.equals("0")) {
                    ps.setInt(3, Integer.parseInt(excludeId));
                }

                try (ResultSet rs = ps.executeQuery()) {
                    boolean first = true;
                    while(rs.next()) {
                        if (!first) json.append(",");
                        json.append("{")
                            .append("\"startTime\":\"").append(rs.getTime("start_time").toString()).append("\",")
                            .append("\"endTime\":\"").append(rs.getTime("end_time").toString()).append("\"")
                            .append("}");
                        first = false;
                    }
                }
            } catch(Exception e) { 
                e.printStackTrace(); 
            }
            json.append("]");
            out.print(json.toString());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        ScheduleDAO dao = new ScheduleDAO();
        
        try {
            if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                dao.deleteSchedule(id);
                request.getSession().setAttribute("message", "Schedule deleted successfully.");
            } 
            else if ("add".equals(action) || "update".equals(action)) {
                int roomId = Integer.parseInt(request.getParameter("roomId"));
                int dayOfWeek = Integer.parseInt(request.getParameter("dayOfWeek"));
                Time startTime = Time.valueOf(request.getParameter("startTime"));
                Time endTime = Time.valueOf(request.getParameter("endTime"));
                int scheduleId = Integer.parseInt(request.getParameter("id"));

                // --- DOUBLE CHECK: Prevent overlap on the server side just in case ---
                boolean hasConflict = false;
                String conflictSql = "SELECT schedule_id FROM lab_schedules WHERE room_id = ? AND day_of_week = ? AND schedule_id != ? " +
                                     "AND (start_time < ? AND end_time > ?)";
                                     
                try (Connection conn = com.lab.util.DBConnection.getConnection();
                     PreparedStatement ps = conn.prepareStatement(conflictSql)) {
                    ps.setInt(1, roomId);
                    ps.setInt(2, dayOfWeek);
                    ps.setInt(3, scheduleId);
                    ps.setTime(4, endTime);   
                    ps.setTime(5, startTime); 
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            hasConflict = true;
                        }
                    }
                }

                if (hasConflict) {
                    request.getSession().setAttribute("error", "Error: The selected time slot overlaps with an existing class in this lab.");
                } else {
                    Schedule s = new Schedule();
                    s.setRoomId(roomId);
                    s.setDayOfWeek(dayOfWeek);
                    s.setStartTime(startTime);
                    s.setEndTime(endTime);
                    s.setSubjectInfo(request.getParameter("subjectInfo"));
                    s.setTahun(Integer.parseInt(request.getParameter("tahun")));

                    if ("add".equals(action)) {
                        dao.addSchedule(s);
                        request.getSession().setAttribute("message", "New class scheduled successfully.");
                    } else {
                        s.setId(scheduleId);
                        dao.updateSchedule(s);
                        request.getSession().setAttribute("message", "Schedule updated successfully.");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("error", "An error occurred processing the schedule.");
        }
        
        response.sendRedirect(request.getContextPath() + "/staff/manage-schedules.jsp");
    }
}