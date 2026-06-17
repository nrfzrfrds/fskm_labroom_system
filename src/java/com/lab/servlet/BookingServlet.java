package com.lab.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.lab.dao.BookingDAO;
import com.lab.model.Booking;
import javax.servlet.http.HttpSession;
import java.util.Map;
import java.util.HashMap;
import com.lab.dao.UserDAO;
import com.lab.model.User;

public class BookingServlet extends HttpServlet {

    private BookingDAO bookingDAO;
    private UserDAO userDAO;
    
    public void init(){
        bookingDAO = new BookingDAO();
        userDAO = new UserDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
            
            String room = request.getParameter("selectedRoom");
            String action = request.getParameter("action");
            
            if ("manageRequests".equals(action)) {
                BookingDAO dao = new BookingDAO();
                List<Booking> bookings = dao.getAllBookings();
                
                Map<Integer,String>userDetails = new HashMap<>();
                for(Booking b:bookings){
                    User user = UserDAO.getUserById(b.getUserId());
                    if(user != null ) userDetails.put(b.getUserId(), user.getName());
                }
                request.setAttribute("bookings", bookings);
                request.setAttribute("userDetails", userDetails);
                request.getRequestDispatcher("/staff/requests.jsp").forward(request, response);
                return;
            }

            if (room != null && !room.trim().isEmpty()) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                PrintWriter out = response.getWriter();

                BookingDAO dao = new BookingDAO();
                List<Booking> list = dao.getUnAvailableLab(room);

                // =====================================================================
                // --- NEW: INJECT STATIC SCHEDULES TO AUTO-DISABLE TIMESLOTS ---
                // =====================================================================
                String scheduleSql = "SELECT ls.day_of_week, ls.start_time, ls.end_time " +
                                     "FROM lab_schedules ls " +
                                     "JOIN lab_rooms lr ON ls.room_id = lr.room_id " +
                                     "WHERE lr.name = ?";
                try (java.sql.Connection conn = com.lab.util.DBConnection.getConnection();
                     java.sql.PreparedStatement ps = conn.prepareStatement(scheduleSql)) {
                    
                    ps.setString(1, room);
                    try (java.sql.ResultSet rs = ps.executeQuery()) {
                        java.util.List<Object[]> staticClasses = new java.util.ArrayList<>();
                        while(rs.next()) {
                            staticClasses.add(new Object[]{ rs.getInt("day_of_week"), rs.getTime("start_time"), rs.getTime("end_time") });
                        }

                        java.util.Calendar cal = java.util.Calendar.getInstance();
                        java.util.Date today = new java.util.Date();

                        // Project these scheduled classes onto the calendar for the next 60 days
                        for (int i = 0; i < 60; i++) {
                            cal.setTime(today);
                            cal.add(java.util.Calendar.DAY_OF_YEAR, i);
                            // Calendar: 1 = Sunday (Ahad), 2 = Monday (Isnin) -> Matches your DB!
                            int currentDayOfWeek = cal.get(java.util.Calendar.DAY_OF_WEEK); 

                            for (Object[] rule : staticClasses) {
                                int ruleDay = (int) rule[0];
                                if (currentDayOfWeek == ruleDay) {
                                    java.sql.Time sTime = (java.sql.Time) rule[1];
                                    java.sql.Time eTime = (java.sql.Time) rule[2];

                                    // Break multi-hour classes into 1-hour blocks so the JS disables all buttons
                                    int startHour = sTime.getHours();
                                    int endHour = eTime.getHours();
                                    for(int h = startHour; h < endHour; h++) {
                                        Booking fakeBooking = new Booking(
                                            new java.sql.Date(cal.getTimeInMillis()), 
                                            room, 0, "system", 
                                            new java.sql.Time(h, 0, 0), 
                                            new java.sql.Time(h+1, 0, 0), 
                                            "Scheduled Class", "approved"
                                        );
                                        list.add(fakeBooking); // Add to the JSON list sent to frontend
                                    }
                                }
                            }
                        }
                    }
                } catch (Exception e) { e.printStackTrace(); }
                // =====================================================================

                StringBuilder json = new StringBuilder("[");
                for (int i = 0; i < list.size(); i++) {
                    Booking b = list.get(i);
                    json.append("{")
                        .append("\"dates\":\"").append(b.getDates()).append("\",")
                        .append("\"startTime\":\"").append(b.getStartTime()).append("\",")
                        .append("\"endTime\":\"").append(b.getEndTime()).append("\"")
                        .append("}");
                    if (i < list.size() - 1) json.append(",");
                }
                json.append("]");

                out.print(json.toString());
                return;
            }

            request.getRequestDispatcher("/book-lab.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            String action = request.getParameter("action");

            if ("approve".equals(action) || "reject".equals(action)) {
                int bookingID = Integer.parseInt(request.getParameter("bookingID"));
                String status = "approve".equals(action) ? "approved" : "rejected";

                BookingDAO dao = new BookingDAO();
                dao.manageBooking(bookingID, status);

                response.sendRedirect(request.getContextPath() + "/BookingServlet?action=manageRequests");
                return;
            }
            
            // --- HANDLE DELETE ACTION ---
            if ("delete".equals(action)) {
                int bookingID = Integer.parseInt(request.getParameter("bookingID"));
                
                // Get the user ID from the session to ensure they own the booking
                HttpSession currentSession = request.getSession(false);
                if(currentSession == null || currentSession.getAttribute("userId") == null){
                    response.sendRedirect(request.getContextPath()+"/auth/index.jsp?mode=login");
                    return;
                }
                int currentUserId = (Integer) currentSession.getAttribute("userId");

                BookingDAO deleteDao = new BookingDAO();
                boolean success = deleteDao.deleteBooking(bookingID, currentUserId);

                if (success) {
                    currentSession.setAttribute("message", "Booking successfully deleted.");
                } else {
                    currentSession.setAttribute("error", "Could not delete the booking.");
                }
                
                response.sendRedirect(request.getContextPath() + "/student/my-bookings.jsp");
                return;
            }
            
            HttpSession session = request.getSession(false);
            if(session == null){
                response.sendRedirect(request.getContextPath()+"/auth/index.jsp?mode=login");
                return;
            }
            
            // 1. Retrieve parameters
            String userType = (String) session.getAttribute("userType");
            String dateParam = request.getParameter("dates");
            String startTimeParam = request.getParameter("startTime");
            String selectedRoom = request.getParameter("selectedRoom");
            String purpose = request.getParameter("purpose");
            String otherPurpose = request.getParameter("other_purpose");
            
            if ("others".equals(purpose) && otherPurpose != null && !otherPurpose.trim().isEmpty()) {
                purpose = otherPurpose.trim();
            }
            
            // 2. Validate
            if (dateParam == null || dateParam.trim().isEmpty() ||
                startTimeParam == null || startTimeParam.trim().isEmpty() ||
                selectedRoom == null || selectedRoom.trim().isEmpty() ||
                userType == null || userType.trim().isEmpty() ||
                purpose == null || purpose.trim().isEmpty()) {
                
                System.err.println("VALIDATION FAILED: One or more fields are null or empty.");
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Validation Failed: Please ensure all required form fields are filled out.");
                return;
            }
            
            // 3. Parse Dates and Force 1-Hour Duration
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd"); 
            SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
            
            java.util.Date utilDates = dateFormat.parse(dateParam);
            java.util.Date utilStartTime = timeFormat.parse(startTimeParam);
            
            // Auto-calculate end time (+ 1 hour)
            Calendar cal = Calendar.getInstance();
            cal.setTime(utilStartTime);
            cal.add(Calendar.HOUR_OF_DAY, 1);
            java.util.Date utilEndTime = cal.getTime();
            
            java.sql.Date dates = new java.sql.Date(utilDates.getTime());
            java.sql.Time startTime = new java.sql.Time(utilStartTime.getTime());
            java.sql.Time endTime = new java.sql.Time(utilEndTime.getTime());

            // =====================================================================
            // --- NEW: SECURITY CHECK TO PREVENT DOUBLE BOOKING WITH STATIC CLASSES 
            // =====================================================================
            java.util.Calendar checkCal = java.util.Calendar.getInstance();
            checkCal.setTime(utilDates);
            int requestedDayOfWeek = checkCal.get(java.util.Calendar.DAY_OF_WEEK);
            int requestedHour = utilStartTime.getHours(); 

            String conflictSql = "SELECT ls.room_id FROM lab_schedules ls " +
                                 "JOIN lab_rooms lr ON ls.room_id = lr.room_id " +
                                 "WHERE lr.name = ? AND ls.day_of_week = ? " +
                                 "AND HOUR(ls.start_time) <= ? AND HOUR(ls.end_time) > ?";
            
            try (java.sql.Connection conn = com.lab.util.DBConnection.getConnection();
                 java.sql.PreparedStatement ps = conn.prepareStatement(conflictSql)) {
                
                ps.setString(1, selectedRoom);
                ps.setInt(2, requestedDayOfWeek);
                ps.setInt(3, requestedHour);
                ps.setInt(4, requestedHour);
                
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) { // A conflict was found!
                        session.setAttribute("error", "Booking Failed: That time slot is occupied by a scheduled academic class.");
                        response.sendRedirect(request.getContextPath() + "/student/book-lab.jsp");
                        return;
                    }
                }
            } catch (Exception e) { e.printStackTrace(); }
            // =====================================================================

            // 4. Save to Database
            Object userIdObj = session.getAttribute("userId");
            if (userIdObj == null) {
                response.sendRedirect(request.getContextPath()+"/auth/index.jsp?mode=login");
                return;
            }
            int userId = (Integer) userIdObj; 
            
            Booking newBooking = new Booking(dates, selectedRoom, userId, userType, startTime, endTime, purpose, "Pending");
            bookingDAO.addBooking(newBooking);
            
            // 5. Redirect to 'My Bookings' based on user role and set success message
            session.setAttribute("message", "Success! Your booking request for " + selectedRoom + " has been recorded.");
        
            if ("staff".equalsIgnoreCase(userType) || "labstaff".equalsIgnoreCase(userType)) {
                response.sendRedirect(request.getContextPath() + "/staff/dashboard.jsp");
            } else {
                // Both Students and Lecturers will now go here!
                response.sendRedirect(request.getContextPath() + "/student/dashboard.jsp");
            }
            
        } catch(Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "An internal server error occurred: " + e.getMessage());
        }
    }
}