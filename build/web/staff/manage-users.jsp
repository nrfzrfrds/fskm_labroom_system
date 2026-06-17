<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="com.lab.model.User"%>
<%
    String ctx = request.getContextPath();
    String currentUser = (String) session.getAttribute("user");
    String currentType = (String) session.getAttribute("userType");
    if (currentUser == null) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    if (!"staff".equalsIgnoreCase(currentType) && !"labstaff".equalsIgnoreCase(currentType)) {
        response.sendRedirect(ctx + "/dashboard.jsp");
        return;
    }

    List<User> users = (List<User>) request.getAttribute("users");
    User selectedUser = (User) request.getAttribute("selectedUser");
    String message = request.getParameter("message");
    String error = request.getParameter("error");
    String errorMessage = (String) request.getAttribute("errorMessage");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Users</title>
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
                <a class="active" href="<%= ctx %>/ManageUsersServlet">Manage Users</a>
                <a href="<%= ctx %>/staff/requests.jsp">Manage Requests</a>
                <a href="<%= ctx %>/staff/reports.jsp">Report and Statistic</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">User Account Management</span>
                        <h1>Manage Users</h1>
                    </div>
                </div>

                <% if (message != null) { %>
                    <div class="alert alert-success"><%= message %></div>
                <% } %>
                <% if (error != null) { %>
                    <div class="alert alert-error"><%= error %></div>
                <% } %>
                <% if (errorMessage != null) { %>
                    <div class="alert alert-error"><%= errorMessage %></div>
                <% } %>

                <table class="user-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Institution ID</th>
                            <th>Email</th>
                            <th>Phone</th>
                            <th>User Type</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (users == null || users.isEmpty()) { %>
                            <tr>
                                <td colspan="7" class="empty-state">No users found in the database.</td>
                            </tr>
                        <% } else { %>
                            <% for (User listedUser : users) { %>
                                <%
                                    String listedType = listedUser.getUserType();
                                    String listedTypeLabel = "staff".equalsIgnoreCase(listedType) || "labstaff".equalsIgnoreCase(listedType)
                                            ? "Staff"
                                            : ("lecturer".equalsIgnoreCase(listedType) ? "Lecturer" : "Student");
                                %>
                                <tr>
                                    <td><%= listedUser.getUserID() %></td>
                                    <td><%= listedUser.getName() %></td>
                                    <td><%= listedUser.getInstitutionId() == null ? "-" : listedUser.getInstitutionId() %></td>
                                    <td><%= listedUser.getEmail() %></td>
                                    <td><%= listedUser.getPhoneNum() %></td>
                                    <td><%= listedTypeLabel %></td>
                                    <td class="action-cell">
                                        <a class="table-btn" href="<%= ctx %>/ManageUsersServlet?editId=<%= listedUser.getUserID() %>">Edit</a>
                                        <form action="<%= ctx %>/ManageUsersServlet" method="POST" class="inline-form" onsubmit="return confirm('Are you sure you want to delete this user account? This action cannot be undone.');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="userID" value="<%= listedUser.getUserID() %>">
                                            <button type="submit" class="table-btn table-btn-danger">Delete</button>
                                        </form>
                                    </td>
                                </tr>
                            <% } %>
                        <% } %>
                    </tbody>
                </table>
            </section>

            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Edit Panel</span>
                        <h2><%= selectedUser == null ? "Select User" : "Update User Details" %></h2>
                    </div>
                </div>
                <% if (selectedUser == null) { %>
                    <div class="empty-form-state">
                        Choose an <strong>Edit</strong> action from the table to load the user information here.
                    </div>
                <% } else { %>
                    <form action="<%= ctx %>/ManageUsersServlet" method="POST" class="stack-form">
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="userID" value="<%= selectedUser.getUserID() %>">

                        <div class="form-row">
                            <div class="form-group">
                                <label>Full Name</label>
                                <input type="text" name="name" value="<%= selectedUser.getName() %>" required>
                            </div>
                            <div class="form-group">
                                <label>Institution ID</label>
                                <input type="text" name="institutionId" value="<%= selectedUser.getInstitutionId() == null ? "" : selectedUser.getInstitutionId() %>" required>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label>Email</label>
                                <input type="email" name="email" value="<%= selectedUser.getEmail() %>" required>
                            </div>
                            <div class="form-group">
                                <label>Phone Number</label>
                                <input type="text" name="phoneNum" value="<%= selectedUser.getPhoneNum() %>" required>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label>User Type</label>
                                <select name="userType" required>
                                    <option value="student" <%= "student".equalsIgnoreCase(selectedUser.getUserType()) ? "selected" : "" %>>Student</option>
                                    <option value="lecturer" <%= "lecturer".equalsIgnoreCase(selectedUser.getUserType()) ? "selected" : "" %>>Lecturer</option>
                                    <option value="staff" <%= ("staff".equalsIgnoreCase(selectedUser.getUserType()) || "labstaff".equalsIgnoreCase(selectedUser.getUserType())) ? "selected" : "" %>>Staff</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>New Password</label>
                                <input type="password" name="password" placeholder="Leave blank to keep existing password">
                            </div>
                        </div>

                        <div class="form-actions compact-actions">
                            <button type="submit" class="table-btn">Update User</button>
                        </div>
                    </form>
                <% } %>
            </section>
        </main>
    </div>
</body>
</html>
