package io.v.android.ui;

import java.lang.CharSequence;
import java.lang.String;

import android.os.Bundle;
import android.widget.RelativeLayout;
import android.widget.EditText;

import android.view.ViewGroup.LayoutParams;
import android.view.inputmethod.InputMethodManager;
import android.content.Context;
import android.text.TextWatcher;
import android.text.Editable;

import android.util.Log; // Log.v(), //Log.d(), //Log.d(), Log.w(), and Log.e()

public class VUIActivity extends io.v.android.VActivity {
	private static final String TAG = "VUIActivity";
	private static VUIActivity thiz;

	private EditText hiddenEditText;
	private RelativeLayout layout;

	private long vApp;
	public VUIActivity() { thiz = this; }

	public static void setVAppPointer(long ptr) {
		thiz.vApp = ptr;
	}

	// This is the "on_soft_input_input" function in V
	public native void onSoftInput(long app, String s, int start, int before, int count);

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		// Create a layout we can add the hidden EditText widget to.
		RelativeLayout myLayout = new RelativeLayout(this);
		this.layout = myLayout;

		// View the content
		setContentView(myLayout);
	}

	// Example of how to entangle soft input visibility into the Activity life-cycle.
	// Needs better handling but it illustrates what can be done.
	@Override
	protected void onStop(){
		super.onStop();
		thiz.hideSoftInput();
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		thiz.hideSoftInput();
	}

	@Override
	protected void onPause(){
		super.onPause();
		thiz.hideSoftInput();
    }

    @Override
	protected void onResume(){
		super.onResume();
		if(thiz.hiddenEditText == null) {
			return;
		}
		thiz.showSoftInput();
    }

    public static void setSoftInputBuffer(String text) {
		if(thiz.hiddenEditText == null) {
			Log.e(TAG,"No keyboard initalized");
			return;
		}
		final EditText editText = thiz.hiddenEditText;
		editText.setText(text);
		editText.post(new Runnable() {
			@Override
			public void run() {
				editText.setSelection(editText.getText().length());
			}
		});
	}

    public static void showSoftInput() {
		//Log.d(TAG,"showSoftInput called");

		final EditText editText = new EditText(thiz);
		thiz.hiddenEditText = editText;

		thiz.runOnUiThread(new Runnable() {
			public void run() {
				//Log.d(TAG,"showSoftInput IN UI THREAD called");

				// Pass two args; must be LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT, or an integer pixel value.
				editText.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

				editText.setEnabled(true);
				editText.setFocusableInTouchMode(true);
				editText.setFocusable(true);

				thiz.layout.addView(editText);

				editText.requestFocus();

				InputMethodManager imm = (InputMethodManager) thiz.getSystemService(Context.INPUT_METHOD_SERVICE);
				imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);

				editText.addTextChangedListener(new TextWatcher() {

					@Override
					public void afterTextChanged(Editable s) { /* TODO Auto-generated method stub */ }

					@Override
					public void beforeTextChanged(CharSequence s, int start, int count, int after) { /* TODO Auto-generated method stub */ }

					@Override
					public void onTextChanged(CharSequence s, int start, int before, int count) {
						// This method is called to notify you that, within s, the count characters beginning at start have just replaced old text that had length before.
						//Log.d(TAG,"Java: "+s.toString());
						// Send it off to V method - we are in the UI thread so it's safe to
						// use the vApp pointer in V here!
						thiz.onSoftInput(thiz.vApp, s.toString(), start, before, count);

					}
				});
			}
		});
	}

	public static void hideSoftInput() {
		//Log.d(TAG,"hideSoftInput called");

		thiz.runOnUiThread(new Runnable() {
			public void run() {
				//Log.d(TAG,"hideSoftInput IN UI THREAD called");
				EditText et = thiz.hiddenEditText;

				if(et == null) {
					return;
				}
				InputMethodManager imm = (InputMethodManager)thiz.getSystemService(Context.INPUT_METHOD_SERVICE);
				imm.hideSoftInputFromWindow(et.getWindowToken(), 0);

				thiz.getWindow().getDecorView().clearFocus();

				if(thiz.hiddenEditText != null) {
					thiz.hiddenEditText = null;
				}
				thiz.getWindow().getDecorView().clearFocus();
			}
		});
	}

}
