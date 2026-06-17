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
    
    if (user == null) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    if (!"staff".equalsIgnoreCase(userType) && !"labstaff".equalsIgnoreCase(userType)) {
        response.sendRedirect(ctx + "/dashboard.jsp");
        return;
    }
    
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
    int totalBookings = bookingDAO.getTotalBookings();
    int pendingCount = bookingDAO.getTotalByStatus("pending");
    int approvedCount = bookingDAO.getTotalByStatus("approved");
    
    List<Booking> recentRequests = bookingDAO.getRecentRequests();
    SimpleDateFormat sdfDate = new SimpleDateFormat("dd MMMM yyyy");
    SimpleDateFormat sdfTime = new SimpleDateFormat("hh:mm a");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lab Staff Dashboard</title>
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
                <span class="eyebrow">Lab Staff Menu</span>
                <h2>FSKM Lab Booking</h2>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%= ctx %>/user/my-account.jsp">My Account</a>
                <a class="active" href="<%= ctx %>/staff/dashboard.jsp">Dashboard</a>
                <a href="<%= ctx %>/staff/view-schedule.jsp">Lab Schedule</a>
                <a href="<%= ctx %>/staff/manage-schedules.jsp">Manage Classes</a>
                <a href="<%= ctx %>/ManageUsersServlet">Manage Users</a>
                <a href="<%= ctx %>/staff/requests.jsp">Manage Requests</a>
                <a href="<%= ctx %>/staff/reports.jsp">Report and Statistic</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            <section class="hero-panel staff-accent">
                <div class="hero-intro">
                    <div class="profile-avatar">
                        <% if (profilePicUrl != null) { %>
                            <img src="<%= profilePicUrl %>" alt="Profile picture of <%= displayName %>">
                        <% } else { %>
                            <span><%= avatarLabel %></span>
                        <% } %>
                    </div>
                    <div>
                    <span class="eyebrow">Lab Staff Dashboard</span>
                    <h1>Welcome, <%= displayName %></h1>
                    <p>Monitor booking activity, review pending requests, manage users, and track lab utilization from one dashboard.</p>
                    </div>
                </div>
                <a class="primary-action" href="<%= ctx %>/staff/requests.jsp">Review Requests</a>
            </section>

            <section class="stats-grid">
                <article class="stat-card">
                    <span class="stat-label">Bookings Made</span>
                    <strong><%= String.format("%02d", totalBookings) %></strong>
                    <p>Total lab bookings recorded.</p>
                </article>
                <article class="stat-card">
                    <span class="stat-label">Awaiting Approval</span>
                    <strong><%= String.format("%02d", pendingCount) %></strong>
                    <p>Requests currently waiting for action.</p>
                </article>
                <article class="stat-card">
                    <span class="stat-label">Confirmed Slots</span>
                    <strong><%= String.format("%02d", approvedCount) %></strong>
                    <p>Confirmed reservations already in the schedule.</p>
                </article>
            </section>

            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Recent Requests</span>
                        <h2>Requested Bookings</h2>
                    </div>
                    <a class="text-link" href="<%= ctx %>/staff/requests.jsp">Open requests page</a>
                </div>
                <div class="request-list">
                    
                    <% 
                        if (recentRequests != null && !recentRequests.isEmpty()) { 
                            for (Booking b : recentRequests) {
                                String formattedDate = sdfDate.format(b.getDates());
                                String formattedStart = sdfTime.format(b.getStartTime());
                                String formattedEnd = sdfTime.format(b.getEndTime());
                                
                                String statusClass = b.getStatus() != null ? b.getStatus().toLowerCase() : "pending";
                                String displayStatus = statusClass.substring(0, 1).toUpperCase() + statusClass.substring(1);
                                
                                // Fetch the name of the user who made the booking
                                User requester = UserDAO.getUserById(b.getUserId());
                                String requesterName = (requester != null) ? requester.getName() : "Unknown User";
                    %>
                    
                    <article class="request-card">
                        <div>
                            <h3><%= requesterName %> - <%= b.getSelectedRoom() %></h3>
                            <p><%= formattedDate %> - <%= formattedStart %> - <%= formattedEnd %></p>
                        </div>
                        <span class="status-pill <%= statusClass %>"><%= displayStatus %></span>
                    </article>
                    
                    <% 
                            }
                        } else { 
                    %>
                        <div class="empty-state">
                            <p>No recent requests found in the database.</p>
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