<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.lab.dao.BookingDAO"%>
<%@page import="com.lab.dao.UserDAO"%>
<%@page import="com.lab.model.Booking"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>

<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.time.LocalDate"%>
<%@page import="java.time.format.DateTimeFormatter"%>
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

    String reportDate = LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    String staffName = user;
    com.lab.model.User profileUser = UserDAO.getUserByEmail(user);
    if (profileUser != null && profileUser.getName() != null && !profileUser.getName().trim().isEmpty()) {
        staffName = profileUser.getName();
    }

    BookingDAO bookingDAO = new BookingDAO();
    SimpleDateFormat sdfDate = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat sdfTime = new SimpleDateFormat("hh:mm a");

    // --- FILTER PARAMS ---
    String filterLab = request.getParameter("filterLab");
    String filterStatus = request.getParameter("filterStatus");
    String filterDateFrom = request.getParameter("filterDateFrom");
    String filterDateTo = request.getParameter("filterDateTo");

    // --- DYNAMIC LAB ROOM BREAKDOWN (normalized to catch naming variants) ---
    List<String> labRooms = bookingDAO.getDistinctLabRooms();
    Map<String, Integer> labCounts = bookingDAO.getLabCountsNormalized(labRooms);
    int totalLabBookings = 0;
    for (int cnt : labCounts.values()) {
        totalLabBookings += cnt;
    }

    // --- BOOKING STATUS COUNTS ---
    int totalBookingsAll = bookingDAO.getTotalBookings();
    int pendingCount = bookingDAO.getTotalByStatus("pending");
    int approvedCount = bookingDAO.getTotalByStatus("approved");
    int rejectedCount = bookingDAO.getTotalByStatus("rejected");
    double approvalRate = totalBookingsAll == 0 ? 0 : (approvedCount * 100.0 / totalBookingsAll);

    // --- USER & SYSTEM STATS ---
    int totalUsers = UserDAO.getTotalUsers();
    int studentUsers = UserDAO.getUserCountByType("student");
    int lecturerUsers = UserDAO.getUserCountByType("lecturer");
    int staffUsers = UserDAO.getUserCountByType("staff");
    int activeBookingUsers = bookingDAO.getTotalDistinctUsersWithBookings();

    // --- MOST USED LAB ---
    String mostUsedLab = "-";
    int mostUsedCount = 0;
    for (Map.Entry<String, Integer> e : labCounts.entrySet()) {
        if (e.getValue() > mostUsedCount) {
            mostUsedCount = e.getValue();
            mostUsedLab = e.getKey();
        }
    }

    // --- FILTERED BOOKINGS ---
    List<Booking> filteredBookings = bookingDAO.getFilteredBookingsWithUsers(filterLab, filterStatus, filterDateFrom, filterDateTo);

    // --- MONTHLY BOOKINGS PER LAB (Bar Chart Data) ---
    Map<String, Map<String, Integer>> monthlyData = bookingDAO.getMonthlyBookingsByLab(labRooms);
    // Build a sorted list of months
    java.util.Set<String> monthKeys = monthlyData.keySet();
    java.util.List<String> monthList = new java.util.ArrayList<>(monthKeys);
    // Determine distinct lab names for bar chart
    java.util.Set<String> barLabs = new java.util.LinkedHashSet<>();
    for (Map<String, Integer> perLab : monthlyData.values()) {
        barLabs.addAll(perLab.keySet());
    }
    barLabs.addAll(labRooms);
    String[] barLabArray = barLabs.toArray(new String[0]);
    // Build a 2D array: rows=months, cols=labs
    int[][] barValues = new int[monthList.size()][barLabArray.length];
    for (int mi = 0; mi < monthList.size(); mi++) {
        java.util.Map<String, Integer> perLab = monthlyData.get(monthList.get(mi));
        for (int li = 0; li < barLabArray.length; li++) {
            if (perLab != null && perLab.containsKey(barLabArray[li])) {
                barValues[mi][li] = perLab.get(barLabArray[li]);
            } else {
                barValues[mi][li] = 0;
            }
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Report and Statistic</title>
    <link rel="stylesheet" type="text/css" href="<%= ctx %>/style.css?v=20260510-sidebar-brand-fix">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
    <style>
        .report-content {
            min-height: calc(100vh - 48px);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            box-sizing: border-box;
        }

        .report-card {
            width: min(100%, 1180px);
            margin: auto;
        }

        .report-summary-row {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 24px;
        }

        .chart-and-stat-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
            margin-top: 26px;
        }

        .chart-container {
            background: #ffffff;
            border-radius: 8px;
            padding: 18px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }

        .chart-container h2 {
            margin: 0 0 14px;
            color: #333333;
            font-size: 1rem;
        }

        .chart-row-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
            margin-top: 26px;
        }

        .stats-grid-2col {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }

        .stat-subsection {
            background: #f9fafc;
            border-radius: 8px;
            padding: 18px 20px;
        }

        .stat-subsection h3 {
            margin: 0 0 12px;
            color: #0b4ea2;
            font-size: 0.85rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .stat-inline {
            display: flex;
            justify-content: space-between;
            padding: 7px 0;
            border-bottom: 1px solid #eef1f6;
            font-size: 0.88rem;
        }

        .stat-inline:last-child {
            border-bottom: none;
        }

        .stat-inline span:last-child {
            font-weight: 700;
            color: #243447;
        }

        /* ---- FILTER ROW ---- */
        .filter-row {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: end;
            margin-top: 20px;
            padding: 16px 0;
            border-top: 1px solid #eef1f6;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .filter-group label {
            font-size: 0.72rem;
            font-weight: 700;
            color: #63758d;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .filter-group input,
        .filter-group select {
            padding: 7px 10px;
            border: 1px solid #d7e3f4;
            border-radius: 6px;
            font-size: 0.85rem;
            min-width: 130px;
        }

        .filter-actions {
            display: flex;
            gap: 8px;
            align-items: end;
        }

        .filter-actions .table-btn {
            padding: 7px 16px;
            min-height: 34px;
            font-size: 0.82rem;
        }

        /* ---- BOOKING TABLE ---- */
        .report-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 12px;
            background: #ffffff;
        }

        .report-table th,
        .report-table td {
            border: 1px solid #ded7ea;
            padding: 10px;
            text-align: left;
        }

        .report-table th {
            background: #0b4ea2;
            color: #ffffff;
            text-transform: uppercase;
            font-size: 0.72rem;
            letter-spacing: 0.04em;
        }

        .report-table-wrap {
            margin-top: 24px;
            overflow-x: auto;
        }

        .chart-canvas-wrap {
            max-height: 260px;
            margin: 0 auto;
            max-width: 320px;
        }

        .pdf-report {
            display: none;
        }

        @media (max-width: 1000px) {
            .report-summary-row {
                grid-template-columns: repeat(2, 1fr);
            }
            .chart-and-stat-row {
                grid-template-columns: 1fr;
            }
            .stats-grid-2col {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 600px) {
            .report-summary-row {
                grid-template-columns: 1fr;
            }
            .filter-row {
                flex-direction: column;
                align-items: stretch;
            }
        }

        @media print {
            @page { size: A4; margin: 14mm; }
            body { background: #ffffff; color: #241f2f; padding: 0; font-family: Arial, Helvetica, sans-serif; }
            .portal-layout { display: block; }
            .side-nav, .content-panel { display: none !important; }
            .pdf-report { display: block; }
            .pdf-header {
                display: grid;
                grid-template-columns: 80px 1fr 180px;
                gap: 18px;
                align-items: start;
                border-bottom: 4px solid #f4b000;
                padding-bottom: 18px;
                margin-bottom: 24px;
            }
            .pdf-logo { height: 72px; width: 72px; object-fit: contain; }
            .pdf-title h1 {
                border: 0; padding: 0; margin: 4px 0 2px;
                color: #083a78; font-size: 1.34rem;
                letter-spacing: 0.04em; text-transform: uppercase;
            }
            .pdf-title h2 {
                margin: 10px 0 0; color: #0b4ea2;
                font-size: 1.04rem; text-transform: uppercase;
            }
            .pdf-title p, .pdf-meta p {
                margin: 0; font-size: 0.72rem;
                text-transform: uppercase; letter-spacing: 0.04em;
            }
            .pdf-stamp {
                display: inline-block; background: #0b4ea2; color: #ffffff;
                padding: 7px 14px; margin-bottom: 14px;
                font-size: 0.64rem; font-weight: 800; text-transform: uppercase;
            }
            .pdf-meta { text-align: right; font-weight: 700; }
            .pdf-score-grid {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 14px; margin: 20px 0 26px;
            }
            .pdf-score {
                border: 1px solid #ded7ea; border-top: 5px solid #f4b000;
                min-height: 80px; display: grid; align-content: center;
                justify-items: center; text-align: center; padding: 10px;
                background: #fbf9ff;
            }
            .pdf-score span {
                font-size: 0.6rem; color: #0b4ea2; text-transform: uppercase;
                letter-spacing: 0.04em; font-weight: 800;
            }
            .pdf-score strong {
                margin-top: 8px; color: #083a78; font-size: 1.5rem; line-height: 1;
            }
            .pdf-score.dark { background: #0b4ea2; border-color: #0b4ea2; border-top-color: #f4b000; }
            .pdf-score.dark span { color: #eee9f7; }
            .pdf-score.dark strong { color: #ffffff; font-size: 0.95rem; line-height: 1.3; text-transform: uppercase; }
            .pdf-section { margin-top: 22px; }
            .pdf-section h2 {
                border-bottom: 2px solid #f4b000; color: #083a78;
                font-size: 0.92rem; letter-spacing: 0.05em;
                margin: 0 0 8px; padding-bottom: 8px; text-transform: uppercase;
            }
            .report-table th, .report-table td {
                border: 1px solid #ded7ea; color: #241f2f;
                font-size: 0.68rem; padding: 8px;
            }
            .report-table th { background: #0b4ea2 !important; color: #ffffff !important; }
            .pdf-footer {
                border-top: 1px solid #ded7ea; color: #0b4ea2;
                font-size: 0.68rem; margin-top: 26px;
                padding-top: 10px; text-align: center; text-transform: uppercase;
            }
        }
    </style>
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
                <a href="<%= ctx %>/staff/requests.jsp">Manage Requests</a>
                <a class="active" href="<%= ctx %>/staff/reports.jsp">Report and Statistic</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel report-content">
            <section class="section-card report-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Report and Statistic</span>
                        <h1>Lab Usage Report</h1>
                    </div>
                    <div class="row-actions">
                        <button class="table-btn" type="button" onclick="window.print()">Download PDF</button>
                    </div>
                </div>

                <div class="report-summary-row">
                    <article class="stat-card">
                        <span class="stat-label">Most Used Lab</span>
                        <strong><%= mostUsedLab %></strong>
                        <p><%= mostUsedCount %> booking(s) — highest usage in this report.</p>
                    </article>
                    <article class="stat-card">
                        <span class="stat-label">Approval Rate</span>
                        <strong><%= String.format(java.util.Locale.US, "%.1f", approvalRate) %>%</strong>
                        <p><%= approvedCount %> approved out of <%= totalBookingsAll %> total.</p>
                    </article>
                    <article class="stat-card">
                        <span class="stat-label">Total Bookings</span>
                        <strong><%= totalBookingsAll %></strong>
                        <p>All booking records in the system.</p>
                    </article>
                    <article class="stat-card">
                        <span class="stat-label">Active Users</span>
                        <strong><%= activeBookingUsers %></strong>
                        <p>Unique users who have made bookings.</p>
                    </article>
                </div>

                <div class="chart-row-2">
                    <div class="chart-container">
                        <h2>FSKM Lab Room Summary</h2>
                        <div style="position:relative; width:100%; min-height: 380px;">
                            <canvas id="labChart"></canvas>
                        </div>
                    </div>
                    <div class="chart-container">
                        <h2>Monthly Booking Trends by Lab</h2>
                        <div style="position:relative; width:100%; min-height: 380px;">
                            <canvas id="monthlyBarChart"></canvas>
                        </div>
                    </div>
                </div>

                <%-- PAGINATION --%>
                <%
                    int pageSize = 5;
                    int currentPage = 1;
                    String pageStr = request.getParameter("page");
                    if (pageStr != null) {
                        try { currentPage = Integer.parseInt(pageStr); if (currentPage < 1) currentPage = 1; }
                        catch (NumberFormatException e) { currentPage = 1; }
                    }
                    int totalBookings = filteredBookings.size();
                    int totalPages = (int) Math.ceil((double) totalBookings / pageSize);
                    if (totalPages < 1) totalPages = 1;
                    if (currentPage > totalPages) currentPage = totalPages;
                    int fromIndex = (currentPage - 1) * pageSize;
                    int toIndex = Math.min(fromIndex + pageSize, totalBookings);
                    List<Booking> pageBookings = filteredBookings.subList(fromIndex, toIndex);

                    // Build query string for pagination links (preserve filters)
                    StringBuilder qs = new StringBuilder();
                    if (filterLab != null && !filterLab.isEmpty()) qs.append("&filterLab=").append(java.net.URLEncoder.encode(filterLab, "UTF-8"));
                    if (filterStatus != null && !filterStatus.isEmpty()) qs.append("&filterStatus=").append(java.net.URLEncoder.encode(filterStatus, "UTF-8"));
                    if (filterDateFrom != null && !filterDateFrom.isEmpty()) qs.append("&filterDateFrom=").append(java.net.URLEncoder.encode(filterDateFrom, "UTF-8"));
                    if (filterDateTo != null && !filterDateTo.isEmpty()) qs.append("&filterDateTo=").append(java.net.URLEncoder.encode(filterDateTo, "UTF-8"));
                %>

                <div style="margin-top: 26px; border-top: 1px solid #eef1f6; padding-top: 16px;">
                    <h3 style="margin:0 0 12px;color:#333;font-size:0.95rem;">Booking Details</h3>

                    <!-- FILTERS (above table) -->
                    <form method="GET" action="<%= ctx %>/staff/reports.jsp" class="filter-row" style="border-top:none;margin-top:0;padding-top:0;">
                        <div class="filter-group">
                            <label>Lab Room</label>
                            <select name="filterLab">
                                <option value="">All Labs</option>
                                <% for (String room : labRooms) { %>
                                    <option value="<%= room %>" <%= room.equals(filterLab) ? "selected" : "" %>><%= room %></option>
                                <% } %>
                            </select>
                        </div>
                        <div class="filter-group">
                            <label>Status</label>
                            <select name="filterStatus">
                                <option value="">All Status</option>
                                <option value="pending" <%= "pending".equals(filterStatus) ? "selected" : "" %>>Pending</option>
                                <option value="approved" <%= "approved".equals(filterStatus) ? "selected" : "" %>>Approved</option>
                                <option value="rejected" <%= "rejected".equals(filterStatus) ? "selected" : "" %>>Rejected</option>
                            </select>
                        </div>
                        <div class="filter-group">
                            <label>From Date</label>
                            <input type="date" name="filterDateFrom" value="<%= filterDateFrom != null ? filterDateFrom : "" %>">
                        </div>
                        <div class="filter-group">
                            <label>To Date</label>
                            <input type="date" name="filterDateTo" value="<%= filterDateTo != null ? filterDateTo : "" %>">
                        </div>
                        <div class="filter-actions">
                            <button type="submit" class="table-btn">Search</button>
                            <button type="button" class="table-btn" style="background:#6b7280;" onclick="window.location.href='<%= ctx %>/staff/reports.jsp'">Reset</button>
                        </div>
                    </form>

                    <!-- BOOKING TABLE -->
                    <div class="report-table-wrap">
                        <table class="report-table">
                            <thead>
                                <tr>
                                    <th>Booking ID</th>
                                    <th>User Name</th>
                                    <th>Lab</th>
                                    <th>Date and Time</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (pageBookings.isEmpty()) { %>
                                <tr><td colspan="5" style="text-align:center;color:#63758d;">No bookings match your filters.</td></tr>
                                <% } else {
                                    for (Booking b : pageBookings) {
                                        String dateStr = b.getDates() != null ? sdfDate.format(b.getDates()) : "-";
                                        String timeStr = b.getStartTime() != null && b.getEndTime() != null
                                            ? sdfTime.format(b.getStartTime()) + " - " + sdfTime.format(b.getEndTime())
                                            : "-";
                                        String bName = b.getUserName() != null ? b.getUserName() : "-";
                                        String statusLabel = b.getStatus() != null
                                            ? b.getStatus().substring(0, 1).toUpperCase() + b.getStatus().substring(1)
                                            : "-";
                                %>
                                <tr>
                                    <td>BK-<%= String.format("%04d", b.getBookingID()) %></td>
                                    <td><%= bName %></td>
                                    <td><%= b.getSelectedRoom() %></td>
                                    <td><%= dateStr %>, <%= timeStr %></td>
                                    <td><%= statusLabel %></td>
                                </tr>
                                <%  } } %>
                            </tbody>
                        </table>
                    </div>

                    <%-- PAGINATION CONTROLS --%>
                    <% if (totalPages > 1) { %>
                    <div style="display:flex;align-items:center;justify-content:center;gap:8px;margin-top:16px;">
                        <% if (currentPage > 1) { %>
                            <a href="<%= ctx %>/staff/reports.jsp?page=<%= currentPage - 1 %><%= qs.toString() %>" class="table-btn" style="background:#6b7280;text-decoration:none;">Previous</a>
                        <% } %>
                        <% for (int p = 1; p <= totalPages; p++) { %>
                            <% if (p == currentPage) { %>
                                <span style="display:inline-flex;align-items:center;justify-content:center;min-width:36px;height:36px;border-radius:6px;background:#0b4ea2;color:#fff;font-weight:800;font-size:0.85rem;"><%= p %></span>
                            <% } else { %>
                                <a href="<%= ctx %>/staff/reports.jsp?page=<%= p %><%= qs.toString() %>" style="display:inline-flex;align-items:center;justify-content:center;min-width:36px;height:36px;border-radius:6px;background:#eef3f8;color:#243447;font-weight:700;font-size:0.85rem;text-decoration:none;"><%= p %></a>
                            <% } %>
                        <% } %>
                        <% if (currentPage < totalPages) { %>
                            <a href="<%= ctx %>/staff/reports.jsp?page=<%= currentPage + 1 %><%= qs.toString() %>" class="table-btn" style="background:#6b7280;text-decoration:none;">Next</a>
                        <% } %>
                    </div>
                    <% } %>
                </div>
            </section>
        </main>

        <section class="pdf-report" aria-label="Printable lab usage report">
            <header class="pdf-header">
                <img class="pdf-logo" src="<%= ctx %>/assets/Logo_Rasmi_UMT.png" alt="Universiti Malaysia Terengganu logo">
                <div class="pdf-title">
                    <h1>FSKM Lab System</h1>
                    <p>Universiti Malaysia Terengganu</p>
                    <h2>Official Facility Usage Report</h2>
                </div>
                <div class="pdf-meta">
                    <span class="pdf-stamp">Official Report</span>
                    <p>Faculty Lab Management</p>
                    <p>Staff Name: <%= staffName %></p>
                    <p>Report Created: <%= reportDate %></p>
                </div>
            </header>

            <div class="pdf-score-grid">
                <div class="pdf-score">
                    <span>Most Used Lab</span>
                    <strong><%= mostUsedLab %></strong>
                </div>
                <div class="pdf-score">
                    <span>Approval Rate</span>
                    <strong><%= String.format(java.util.Locale.US, "%.1f", approvalRate) %>%</strong>
                </div>
                <div class="pdf-score">
                    <span>Total Bookings</span>
                    <strong><%= totalBookingsAll %></strong>
                </div>
                <div class="pdf-score dark">
                    <span>Registered Users</span>
                    <strong><%= totalUsers %> Accounts</strong>
                </div>
            </div>

            <section class="pdf-section">
                <h2>FSKM Lab Room Breakdown</h2>
                <table class="report-table">
                    <thead>
                        <tr>
                            <th>Laboratory Name</th>
                            <th>Total Bookings</th>
                            <th>Usage Share</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (labCounts.isEmpty()) { %>
                        <tr><td colspan="3">No booking data available.</td></tr>
                        <% } else {
                            for (Map.Entry<String, Integer> entry : labCounts.entrySet()) {
                                String rn = entry.getKey();
                                int cnt = entry.getValue();
                                double pct = totalLabBookings == 0 ? 0 : (cnt * 100.0 / totalLabBookings);
                        %>
                        <tr>
                            <td><%= rn %></td>
                            <td><%= cnt %></td>
                            <td><%= String.format(java.util.Locale.US, "%.0f%%", pct) %></td>
                        </tr>
                        <%  } } %>
                    </tbody>
                </table>
            </section>

            <section class="pdf-section">
                <h2>Booking Status &amp; User Summary</h2>
                <table class="report-table">
                    <thead>
                        <tr>
                            <th>Metric</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td>Approved Bookings</td><td><%= approvedCount %></td></tr>
                        <tr><td>Pending Bookings</td><td><%= pendingCount %></td></tr>
                        <tr><td>Rejected Bookings</td><td><%= rejectedCount %></td></tr>
                        <tr><td>Total Registered Users</td><td><%= totalUsers %></td></tr>
                        <tr><td>Students</td><td><%= studentUsers %></td></tr>
                        <tr><td>Lecturers</td><td><%= lecturerUsers %></td></tr>
                        <tr><td>Staff</td><td><%= staffUsers %></td></tr>
                    </tbody>
                </table>
            </section>

            <section class="pdf-section">
                <h2>Complete Booking Details</h2>
                <table class="report-table">
                    <thead>
                        <tr>
                            <th>Booking ID</th>
                            <th>User Name</th>
                            <th>Lab</th>
                            <th>Date and Time</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (filteredBookings.isEmpty()) { %>
                        <tr><td colspan="5">No bookings found.</td></tr>
                        <% } else {
                            for (Booking b : filteredBookings) {
                                String dateStr = b.getDates() != null ? sdfDate.format(b.getDates()) : "-";
                                String timeStr = b.getStartTime() != null && b.getEndTime() != null
                                    ? sdfTime.format(b.getStartTime()) + " - " + sdfTime.format(b.getEndTime())
                                    : "-";
                                String bName = b.getUserName() != null ? b.getUserName() : "-";
                                String st = b.getStatus() != null
                                    ? b.getStatus().substring(0, 1).toUpperCase() + b.getStatus().substring(1)
                                    : "-";
                        %>
                        <tr>
                            <td>BK-<%= String.format("%04d", b.getBookingID()) %></td>
                            <td><%= bName %></td>
                            <td><%= b.getSelectedRoom() %></td>
                            <td><%= dateStr %>, <%= timeStr %></td>
                            <td><%= st %></td>
                        </tr>
                        <%  } } %>
                    </tbody>
                </table>
            </section>

            <div class="pdf-footer">
                FSKM Lab Room Booking System | Universiti Malaysia Terengganu
            </div>
        </section>
    </div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // ── Doughnut Chart (Lab Room Summary) ──
    var ctx = document.getElementById('labChart').getContext('2d');
    var colors = [
        '#0b4ea2', '#f4b000', '#2ecc71', '#e74c3c', '#9b59b6',
        '#1abc9c', '#e67e22', '#3498db', '#34495e', '#16a085',
        '#c0392b', '#8e44ad', '#d35400', '#27ae60', '#2980b9'
    ];
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: [
                <% for (int i = 0; i < labRooms.size(); i++) {
                    String r = labRooms.get(i);
                    out.print("'" + r.replace("'", "\\'") + "'");
                    if (i < labRooms.size() - 1) out.print(",");
                } %>
            ],
            datasets: [{
                data: [
                    <% for (int i = 0; i < labRooms.size(); i++) {
                        out.print(labCounts.get(labRooms.get(i)));
                        if (i < labRooms.size() - 1) out.print(",");
                    } %>
                ],
                backgroundColor: colors.slice(0, <%= labRooms.size() %>),
                borderWidth: 2,
                borderColor: '#ffffff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        font: { size: 10 },
                        padding: 10,
                        boxWidth: 12,
                        generateLabels: function(chart) {
                            var data = chart.data;
                            return data.labels.map(function(label, i) {
                                var val = data.datasets[0].data[i];
                                return {
                                    text: label + ' (' + val + ')',
                                    fillStyle: data.datasets[0].backgroundColor[i],
                                    strokeStyle: '#ffffff',
                                    lineWidth: 2,
                                    index: i
                                };
                            });
                        }
                    }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            var total = context.dataset.data.reduce(function(a, b) { return a + b; }, 0);
                            var pct = total === 0 ? 0 : (context.parsed / total * 100).toFixed(1);
                            return ' ' + context.parsed + ' booking(s) (' + pct + '%)';
                        }
                    }
                }
            }
        }
    });

    // ── Bar Chart (Monthly Booking Trends by Lab) ──
    var barCtx = document.getElementById('monthlyBarChart').getContext('2d');

    var monthLabels = [
        <% for (int i = 0; i < monthList.size(); i++) {
            out.print("'" + monthList.get(i) + "'");
            if (i < monthList.size() - 1) out.print(",");
        } %>
    ];

    var barLabArrayJS = [
        <% for (int i = 0; i < barLabArray.length; i++) {
            out.print("'" + barLabArray[i].replace("'", "\\'") + "'");
            if (i < barLabArray.length - 1) out.print(",");
        } %>
    ];

    var barValues = [
        <% for (int mi = 0; mi < monthList.size(); mi++) { %>
            [<% for (int li = 0; li < barLabArray.length; li++) {
                out.print(barValues[mi][li]);
                if (li < barLabArray.length - 1) out.print(",");
            } %>]<% if (mi < monthList.size() - 1) out.print(","); %>
        <% } %>
    ];

    var barDatasets = [];
    for (var li = 0; li < barLabArrayJS.length; li++) {
        var data = [];
        for (var mi = 0; mi < monthLabels.length; mi++) {
            data.push(barValues[mi][li]);
        }
        barDatasets.push({
            label: barLabArrayJS[li],
            data: data,
            backgroundColor: colors[li % colors.length],
            borderRadius: 4,
            borderSkipped: false,
        });
    }

    new Chart(barCtx, {
        type: 'bar',
        data: {
            labels: monthLabels,
            datasets: barDatasets
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'index',
                intersect: false
            },
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { font: { size: 10 }, padding: 12, boxWidth: 14 }
                },
                tooltip: {
                    callbacks: {
                        title: function(items) { return items[0].label; },
                        label: function(context) {
                            return context.dataset.label + ': ' + context.parsed.y + ' booking(s)';
                        }
                    }
                }
            },
            scales: {
                x: {
                    stacked: false,
                    grid: { display: false },
                    ticks: { font: { size: 10 } }
                },
                y: {
                    stacked: false,
                    beginAtZero: true,
                    ticks: { 
                        precision: 0,
                        font: { size: 10 }
                    },
                    title: {
                        display: true,
                        text: 'Number of Bookings',
                        font: { size: 11 }
                    }
                }
            }
        }
    });
});
</script>
</body>
</html>
