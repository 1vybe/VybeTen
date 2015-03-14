var _ = require('underscore');
var Tribe = Parse.Object.extend('Tribe');

Parse.Cloud.afterSave('Tribe', function (request, response) {
	if (request.object.existed()) {
		return;
	}

	var user = request.user;

	var type = request.object.get('isPublic');
	if (type) {
		var acl = new Parse.ACL();
		acl.setPublicReadAccess(true);
		acl.setWriteAccess(user, true);

		request.object.setACL(acl);
		return request.object.save();
	} else {	
		var members = request.object.relation('members');
		var query = members.query();
		return query.find().then(function (userObjs) {
			var roleName = 'membersOf_' + request.object.id;
			var role = new Parse.Role(roleName, new Parse.ACL(user));

			_.each(userObjs, function (obj) {
				role.getUsers().add(obj);
			})

			return role.save().then(function (role) {
				var acl = new Parse.ACL();
				acl.setRoleReadAccess(role, true);
				acl.setRoleWriteAccess(role, true);

				request.object.setACL(acl);
				return request.object.save();
			});
		});
	}

});

// This function takes one argument 'tribeId' - objectID of the tribe
Parse.Cloud.define('removeFromRole', function (request, response) {
	var userId = request.params.userId;
	var user = new Parse.User();
	user.id = userId;
	user.fetch();

	var tribeId = request.params.tribeId;
	var roleName = 'membersOf_' + tribeId;
	var query = new Parse.Query(Parse.Role);
	query.equalTo('name', roleName);

	query.first().then(function (roleObj) {
		if (roleObj) {
			roleObj.getUsers().remove(user);
			return roleObj.save();
		} else {
			response.error('No role exists for User_' + user.id);
		}
	}, function (error) {
			response.error('No role exists for User_' + user.id);
	}).then(function (roleObj) {
		response.success('User_' + user.id + ' successfully removed from Role_' + roleObj);
	});
});

Parse.Cloud.define('grantRole', function (request, response) {
	var userId = request.params.userId;
	var user = new Parse.User();
	user.id = userId;
	user.fetch();

	var tribeId = request.params.tribeId;
	var roleName = 'membersOf_' + tribeId;
	var query = new Parse.Query(Parse.Role);
	query.equalTo('name', roleName);

	console.log('Granting User_' + user.id + ' Role_' + roleName);
	query.first().then(function (roleObj) {
		if (roleObj) {
			roleObj.getUsers().add(user);
			return roleObj.save();
		} else {
			response.error('No role exists for User_' + user.id);
		}
	}, function (error) {
		response.error('No role exists for User_' + user.id);
	}).then(function (roleObj) {
		response.success('User_' + user.id + ' successfully granted Role_' + roleObj);
	});
});






