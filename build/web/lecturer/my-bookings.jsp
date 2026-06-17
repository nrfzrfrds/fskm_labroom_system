<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="com.lab.model.Booking"%>
<%@page import="com.lab.dao.BookingDAO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%
    String ctx = request.getContextPath();
    String user = (String) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    Integer userId = (Integer) session.getAttribute("userId"); // We need this to get your specific bookings!
    
    if (user == null || userId == null) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    // Allow BOTH Students and Lecturers to view this page
    if (!"student".equalsIgnoreCase(userType) && !"lecturer".equalsIgnoreCase(userType)) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    // Create a dynamic title based on their role
    String displayRole = "lecturer".equalsIgnoreCase(userType) ? "Lecturer" : "Student";

    // 1. Talk to the database and get YOUR real bookings
    BookingDAO dao = new BookingDAO();
    List<Booking> myBookings = dao.getBookingsByUserId(userId);

    // 2. Setup formatters to make the SQL dates look pretty
    SimpleDateFormat sdfDate = new SimpleDateFormat("dd MMMM yyyy");
    SimpleDateFormat sdfTime = new SimpleDateFormat("hh:mm a");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Bookings</title>
    <link rel="stylesheet" type="text/css" href="<%= ctx %>/style.css?v=20260510-sidebar-brand-fix">
</head>
<body class="portal-shell">
    <div class="portal-layout">
        <aside class="side-nav">
            <div class="brand-lockup">
                <span class="sidebar-logo-badge">
                    <img class="sidebar-logo" src="<%= ctx %>/assets/Logo_Rasmi_UMT_sidebar.png" alt="Universiti Malaysia Terengganu logo">
                </span>
                <div>
                <span class="eyebrow">Lecturer Menu</span>
                <h2>FSKM Lab Booking</h2>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%= ctx %>/user/my-account.jsp">My Account</a>
                <a href="dashboard.jsp">Dashboard</a>
                <a href="book-lab.jsp">Book Lab Room</a>
                <a class="active" href="my-bookings.jsp">My Bookings</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            
            <%-- This catches the success message from the booking form --%>
            <%
                String msg = (String) session.getAttribute("message");
                if (msg != null) {
            %>
                <div class="alert alert-success" style="margin-bottom: 20px;">
                    <strong><%= msg %></strong>
                </div>
            <%
                    session.removeAttribute("message");
                }
            %>

            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Reservation List</span>
                        <h1>My Bookings</h1>
                    </div>
                </div>
                
                <div class="request-list">
                    <% 
                        // 3. Loop through the database results and print real HTML rows!
                        if (myBookings != null && !myBookings.isEmpty()) { 
                            for (Booking b : myBookings) {
                                String formattedDate = sdfDate.format(b.getDates());
                                String formattedStart = sdfTime.format(b.getStartTime());
                                String formattedEnd = sdfTime.format(b.getEndTime());
                                
                                String statusClass = b.getStatus() != null ? b.getStatus().toLowerCase() : "pending";
                                String displayStatus = statusClass.substring(0, 1).toUpperCase() + statusClass.substring(1);
                    %>
                    
                    <article class="booking-row request-card rich-card">
                        <div>
                            <h3><%= b.getSelectedRoom() %></h3>
                            <p><%= formattedDate %> &bull; <%= formattedStart %> - <%= formattedEnd %></p>
                            <p class="muted">Purpose: <%= b.getPurpose() %></p>
                        </div>
                        <div class="row-actions">
                            <span class="status-pill <%= statusClass %>"><%= displayStatus %></span>
                            
                            <%-- THE NEW EDIT & DELETE BUTTONS --%>
                            <button class="table-btn" type="button" onclick="alert('To edit this booking, please delete it and submit a new request for the correct time.')">Edit</button>

                            <form action="<%= ctx %>/BookingServlet" method="POST" style="display:inline;" onsubmit="return confirm('Are you sure you want to permanently delete this booking?');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="bookingID" value="<%= b.getBookingID() %>">
                                <button type="submit" class="table-btn table-btn-danger">Delete</button>
                            </form>
                        </div>
                    </article>
                    
                    <% 
                            } 
                        } else { 
                    %>
                        <%-- What to show if the database is empty --%>
                        <div class="empty-state">
                            <p>You haven't made any lab bookings yet. Go book a room!</p>
                        </div>
                    <% 
                        } 
                    %>
                </div>
                
            </section>
        </main>
    </div>
</body>
</html>