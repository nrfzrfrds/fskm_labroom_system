<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.lab.dao.UserDAO"%>
<%@page import="com.lab.model.User"%>
<%@page import="com.lab.dao.BookingDAO"%>
<%@page import="com.lab.model.Booking"%>
<%@page import="java.util.List"%>
<%@page import="java.text.SimpleDateFormat"%>
<%
    String ctx = request.getContextPath();
    String user = (String) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    Integer userId = (Integer) session.getAttribute("userId"); // Needed for database queries
    
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
    
    // --- GET USER PROFILE INFO ---
    String displayName = user;
    String profilePic = null;
    User profileUser = UserDAO.getUserByEmail(user);
    if (profileUser != null) {
        if (profileUser.getName() != null && !profileUser.getName().trim().isEmpty()) {
            displayName = profileUser.getName();
        }
        profilePic = profileUser.getProfilePic();
    }
    String avatarLabel = displayName != null && !displayName.trim().isEmpty()
            ? displayName.trim().substring(0, 1).toUpperCase()
            : "U";
    String profilePicUrl = profilePic != null && !profilePic.trim().isEmpty() ? ctx + profilePic : null;
    
    // --- GET DYNAMIC BOOKING STATS ---
    BookingDAO bookingDAO = new BookingDAO();
    int pendingCount = bookingDAO.getTotalByStatusAndUser("pending", userId);
    int approvedCount = bookingDAO.getTotalByStatusAndUser("approved", userId);
    String recentLab = bookingDAO.getRecentLab(userId);
    
    // Get list of bookings to display in the recent section
    List<Booking> myBookings = bookingDAO.getBookingsByUserId(userId);
    SimpleDateFormat sdfDate = new SimpleDateFormat("dd MMMM yyyy");
    SimpleDateFormat sdfTime = new SimpleDateFormat("hh:mm a");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Student Dashboard</title>
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
                <a class="active" href="dashboard.jsp">Dashboard</a>
                <a href="book-lab.jsp">Book Lab Room</a>
                <a href="my-bookings.jsp">My Bookings</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            <section class="hero-panel student-accent">
                <div class="hero-intro">
                    <div class="profile-avatar">
                        <% if (profilePicUrl != null) { %>
                            <img src="<%= profilePicUrl %>" alt="Profile picture of <%= displayName %>">
                        <% } else { %>
                            <span><%= avatarLabel %></span>
                        <% } %>
                    </div>
                    <div>
                    <span class="eyebrow">Lecturer Dashboard</span>
                    <h1>Welcome, <%= displayName %></h1>
                    <p>Check lab availability, submit new bookings, and track the latest status of your reservations.</p>
                    </div>
                </div>
                <a class="primary-action" href="book-lab.jsp">Book a Lab</a>
            </section>

            <section class="stats-grid">
                <article class="stat-card">
                    <span class="stat-label">Pending</span>
                    <strong><%= String.format("%02d", pendingCount) %></strong>
                    <p>Requests waiting for staff approval.</p>
                </article>
                <article class="stat-card">
                    <span class="stat-label">Approved</span>
                    <strong><%= String.format("%02d", approvedCount) %></strong>
                    <p>Confirmed bookings in your account.</p>
                </article>
                <article class="stat-card">
                    <span class="stat-label">Recent Lab</span>
                    <strong><%= recentLab %></strong>
                    <p>Your latest requested room.</p>
                </article>
            </section>

            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Recent Bookings</span>
                        <h2>Booking Status</h2>
                    </div>
                    <a class="text-link" href="my-bookings.jsp">View all</a>
                </div>
                
                <div class="request-list">
                    <% 
                        if (myBookings != null && !myBookings.isEmpty()) { 
                            // Only show a maximum of 2 recent bookings on the dashboard
                            int limit = Math.min(2, myBookings.size());
                            for (int i = 0; i < limit; i++) {
                                Booking b = myBookings.get(i);
                                String formattedDate = sdfDate.format(b.getDates());
                                String formattedStart = sdfTime.format(b.getStartTime());
                                String formattedEnd = sdfTime.format(b.getEndTime());
                                
                                String statusClass = b.getStatus() != null ? b.getStatus().toLowerCase() : "pending";
                                String displayStatus = statusClass.substring(0, 1).toUpperCase() + statusClass.substring(1);
                    %>
                    <article class="request-card">
                        <div>
                            <h3><%= b.getSelectedRoom() %></h3>
                            <p><%= formattedDate %> &bull; <%= formattedStart %> - <%= formattedEnd %></p>
                        </div>
                        <span class="status-pill <%= statusClass %>"><%= displayStatus %></span>
                    </article>
                    <% 
                            }
                        } else { 
                    %>
                        <div class="empty-state">
                            <p>You haven't made any lab bookings yet.</p>
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