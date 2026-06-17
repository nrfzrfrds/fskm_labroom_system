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

    // Fetch all bookings
    BookingDAO dao = new BookingDAO();
    List<Booking> allBookings = dao.getAllBookings();

    SimpleDateFormat sdfDate = new SimpleDateFormat("dd MMMM yyyy");
    SimpleDateFormat sdfTime = new SimpleDateFormat("hh:mm a");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Requests</title>
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
                <a href="<%= ctx %>/staff/dashboard.jsp">Dashboard</a>
                <a href="<%= ctx %>/staff/view-schedule.jsp">Lab Schedule</a>
                <a href="<%= ctx %>/staff/manage-schedules.jsp">Manage Classes</a>
                <a href="<%= ctx %>/ManageUsersServlet">Manage Users</a>
                <a class="active" href="<%= ctx %>/staff/requests.jsp">Manage Requests</a>
                <a href="<%= ctx %>/staff/reports.jsp">Report and Statistic</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Booking Review</span>
                        <h1>Manage Requests</h1>
                    </div>
                </div>
                
                <%-- 1. UPDATED FILTER BUTTONS --%>
                <div class="filter-row">
                    <button class="filter-chip active" onclick="filterRequests('all', this)">All</button>
                    <button class="filter-chip" onclick="filterRequests('pending', this)">Pending</button>
                    <button class="filter-chip" onclick="filterRequests('approved', this)">Approved</button>
                    <button class="filter-chip" onclick="filterRequests('rejected', this)">Rejected</button>
                </div>
                
                <div class="request-list">
                    
                    <% 
                        if (allBookings != null && !allBookings.isEmpty()) { 
                            for (Booking b : allBookings) {
                                String formattedDate = sdfDate.format(b.getDates());
                                String formattedStart = sdfTime.format(b.getStartTime());
                                String formattedEnd = sdfTime.format(b.getEndTime());
                                
                                String statusClass = b.getStatus() != null ? b.getStatus().toLowerCase() : "pending";
                                String displayStatus = statusClass.substring(0, 1).toUpperCase() + statusClass.substring(1);
                                
                                User requester = UserDAO.getUserById(b.getUserId());
                                String requesterName = (requester != null) ? requester.getName() : "Unknown User";
                    %>
                    
                    <%-- 2. ADDED data-status ATTRIBUTE SO JAVASCRIPT CAN READ IT --%>
                    <article class="request-card rich-card" data-status="<%= statusClass %>">
                        <div>
                            <h3><%= displayStatus %> - <%= requesterName %></h3>
                            <p><%= b.getSelectedRoom() %> - <%= formattedDate %> - <%= formattedStart %> - <%= formattedEnd %></p>
                            <p class="muted">Purpose: <%= b.getPurpose() %></p>
                        </div>
                        <div class="row-actions">
                            <span class="status-pill <%= statusClass %>"><%= displayStatus %></span>
                            
                            <% if ("pending".equals(statusClass)) { %>
                                <form action="<%= ctx %>/BookingServlet" method="POST" style="display:inline;">
                                    <input type="hidden" name="action" value="approve">
                                    <input type="hidden" name="bookingID" value="<%= b.getBookingID() %>">
                                    <button type="submit" class="table-btn" style="background-color: #13683a;">Approve</button>
                                </form>
                                
                                <form action="<%= ctx %>/BookingServlet" method="POST" style="display:inline;">
                                    <input type="hidden" name="action" value="reject">
                                    <input type="hidden" name="bookingID" value="<%= b.getBookingID() %>">
                                    <button type="submit" class="table-btn table-btn-danger">Reject</button>
                                </form>
                            <% } %>
                            
                        </div>
                    </article>
                    
                    <% 
                            }
                        } else { 
                    %>
                        <div class="empty-state" id="mainEmptyState">
                            <p>There are no booking requests in the system.</p>
                        </div>
                    <% 
                        } 
                    %>
                    
                    <%-- Hidden empty state for when filters return 0 results --%>
                    <div class="empty-state" id="filterEmptyState" style="display: none;">
                        <p>No requests found for this status.</p>
                    </div>
                    
                </div>
            </section>
        </main>
    </div>

    <%-- 3. THE JAVASCRIPT FILTER LOGIC --%>
    <script>
        function filterRequests(statusTarget, clickedButton) {
            // Step A: Make the clicked button turn blue (active) and reset the others
            const chips = document.querySelectorAll('.filter-chip');
            chips.forEach(chip => chip.classList.remove('active'));
            clickedButton.classList.add('active');

            // Step B: Grab all the booking cards
            const cards = document.querySelectorAll('.request-card');
            let visibleCount = 0;

            // Step C: Loop through them and hide/show based on the data-status
            cards.forEach(card => {
                const cardStatus = card.getAttribute('data-status');
                
                if (statusTarget === 'all' || cardStatus === statusTarget) {
                    card.style.display = 'flex'; // Use flex to preserve your layout CSS
                    visibleCount++;
                } else {
                    card.style.display = 'none';
                }
            });

            // Step D: If the filter hides everything, show a "No requests found" message
            const filterEmptyState = document.getElementById('filterEmptyState');
            const mainEmptyState = document.getElementById('mainEmptyState');
            
            if (visibleCount === 0 && !mainEmptyState) {
                filterEmptyState.style.display = 'block';
            } else {
                filterEmptyState.style.display = 'none';
            }
        }
    </script>
</body>
</html>